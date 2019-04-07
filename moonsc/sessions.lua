-- The MIT License (MIT)
--
-- Copyright (c) 2019 Stefano Trettel
--
-- Software repository: MoonSC, https://github.com/stetre/moonsc
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

-------------------------------------------------------------------------------
--*** DO NOT require() THIS MODULE (it is loaded automatically by MoonSC) ***--
-------------------------------------------------------------------------------

local moonsc, internal
 -- imported functions:
local now, start_session, loop_iteration, new_env, path
local copy_statechart, validate_statechart, delete_dynamic_id
local delay_push, delay_pop, delay_tnext, delay_reset
-- callbacks:
local error_callback, send_callback
-- shortcuts
local string_match = string.match

-------------------------------------------------------------------------------
-- Sessions database
-------------------------------------------------------------------------------
local Nsessions = 0 -- number of sessions
local Sessions = {} -- Sessions[sessionid] = validated <scxml> element

local function find_session(sessionid)
   local scxml = Sessions[sessionid]
   if not scxml then error("unknown sessionid '"..sessionid.."'", 2) end
   return scxml
end

local generate_sessionid = (function()
   local i = 0
   return function()
      local sessionid 
      while true do
         i = i + 1
         sessionid = 'session'..i
         if not Sessions[sessionid] then return sessionid end
      end
   end
end)()

-------------------------------------------------------------------------------
-- System variables
-------------------------------------------------------------------------------

local IoProcessors = {} -- the content of the _ioprocessor system variable
IoProcessors['scxml'] = { location="localhost" }

local function add_ioprocessor(ptype, location, info)
   local entry = { location = location }
   if info then for k, v in pairs(info) do entry[k] = v end end
   IoProcessors[ptype] = entry
end

local function set_event(scxml, eventinfo)
   scxml._ENV._event = eventinfo
end

local function set_system_variables(scxml)
-- Sets the system variables in the session's dedicated environment
   local env = scxml._ENV
   env._sessionid = scxml._sessionid
   env._name = scxml.name
   env._ioprocessors = IoProcessors
   if scxml._invokeinfo then env._invokeid = scxml._invokeinfo.invokeid end
-- env._x = {} at session initialization
end

local is_readonly = (function()
-- is_readonly(location) = true if location cannot be assigned to
      local locations = { -- list of readonly locations
         '_ENV', '_sessionid', '_name', '_ioprocessors', '_invokeid', '_event', '_x',
      }
      local t = {} -- reverse
      for _, loc in ipairs(locations) do t[loc] = true end
      return function(location)
         if t[location] then return true end
         -- test also that location is not a nested field of readonly variables
         -- (e.g. _event.something or _event[something])
         return t[ string_match(location, "^(.+)[%.%[]")] or false
      end
   end)()

local function ioprocessor_supported(sendtype)
   return IoProcessors[sendtype] and true or false
end

-------------------------------------------------------------------------------
-- I/O Processor
-------------------------------------------------------------------------------

local function raise_event(scxml, eventinfo)
   scxml._intqueue:push(eventinfo)
   scxml._macrostep=true
end

local function raise(sessionid, name, data)
   local scxml = find_session(sessionid)
   if type(name)=='table' then
      raise_event(scxml, name) -- name is an eventinfo
   else
      raise_event(scxml, { name=name, type='platform', data=data })
   end
end

local function send_error(what, element, errmsg, sendid)
   raise_event(element._root, {name=what, type='platform', sendid=sendid})
   if error_callback then
      local errmsg = "in element "..path(element)..":\n"..errmsg
      error_callback(element._root._sessionid, what, errmsg)
   end
   return false
end

local function error_noaction(element, errmsg)
-- trace only, without sending back an error event
   if error_callback then
      local errmsg = "in element "..path(element)..":\n"..errmsg
      error_callback(element._root._sessionid, 'noaction', errmsg)
   end
   return false
end

local function error_execution(element, errmsg, sendid)
   return send_error('error.execution', element, errmsg, sendid)
end

local function error_communication(element, errmsg, sendid)
   return send_error('error.communication', element, errmsg, sendid)
end

local function send_event(scxml, eventinfo) --@@ sanitize event
   local t = eventinfo.type
   if t == 'external' then
      scxml._extqueue:push(eventinfo)
   elseif t == 'internal' or t=='platform' then
      scxml._intqueue:push(eventinfo)
      scxml._macrostep=true
   else
      error("invalid eventinfo.type")
   end
end

local function send(sessionid, name, data)
-- Used by the application to send an event to the session identified by sessionid
   local scxml = find_session(sessionid)
   if type(name)=='table' then
      send_event(scxml, name) -- name is an eventinfo
   else
      send_event(scxml, {
         name = name,
         type = 'external',
         origin = IoProcessors['scxml'].location,
         origintype = 'scxml',
         data = data,
      })
   end
end

local function autoroute(scxml, sendinfo)
-- Attempts to automatically route a <send> with type='scxml'.
-- Returns true on success, false on failure.
   local target = sendinfo.target
   local destination, eventinfo, invokeid
   if not target or target==IoProcessors['scxml'].location then
      -- with no target, or if target is the local location, means 'send to self'
      destination = scxml
      eventinfo = {
         type='external',
         name = sendinfo.event,
         origintype = 'scxml',
         origin = IoProcessors['scxml'].location,
         sendid = sendinfo.sendid,
         data = sendinfo.data,
      }
   elseif target:sub(1,2) ~= '#_' then -- not a special target
      return false
   elseif target=='#_internal' then -- send to self as 'internal'
      raise_event(scxml, {
         name=sendinfo.event,
         type='internal',
         data = sendinfo.data,
      })
      return true
   elseif target=='#_parent' then -- send to the parent session
      local invokeinfo = scxml._invokeinfo
      if not invokeinfo then return false end -- not a child session
      destination = Sessions[invokeinfo.parentid]
      invokeid = invokeinfo.invokeid
   else
      local sessionid = string_match(target, '^#_scxml_([%w_]+)') -- '#_scxml_sessionid'
      if sessionid then -- destination is the session identified by sessionid
         destination = Sessions[sessionid]
      else
         local id = string_match(target, '^#_([%w_%.]+)') -- '#_invokeid'
         if id then -- destination is the child session whose invokeid is id
            destination = Sessions[scxml._childsession[id]]
         end
      end
   end
   -----------------------------------------------------------
   if not destination then return false end -- not local, or no more running?
   local eventinfo = eventinfo or {
      type = 'external',
      name = sendinfo.event,
      sendid = sendinfo.sendid,
      origin = IoProcessors['scxml'].location,
      origintype = 'scxml',
      invokeid = invokeid or nil,
      data = sendinfo.data,
   }
   destination._extqueue:push(eventinfo)
   return true
end

local function dispatch_send(sendinfo)
   local element = sendinfo.element
   local scxml = element._root
   local sessionid = scxml._sessionid -- source
   local sendid = sendinfo.sendid
   sendinfo.element = nil -- don't let the user access this
   sendinfo.sourceid = scxml._sessionid
   if sendid then
      delete_dynamic_id(element, sendid)
      if element._omit_sendid then
         sendid, sendinfo.sendid = nil
      end
   end
   if scxml._dont_send then return true end
   if sendinfo.type=='scxml' and autoroute(scxml, sendinfo) then return true end
   local ok, success = false, "invalid or unsupported target"
   if send_callback then
      ok, success = pcall(send_callback, sendinfo)
      if ok and success then return true end
   end
   -- Here there are cases where we must send back a 'error.communication' (e.g. the
   -- destination is unreachable) and cases where we must send back a 'error.execution'
   -- (e.g if type='scxml' and target is invalid or not supported).
   if success then -- success = error message
      error_execution(element, success, sendid)
   else -- success is nil or false if the callback was unable to route
      error_communication(element, "unable to route message", sendid)
   end
   return false
end

local function delay_send(sendinfo, at)
   return delay_push(sendinfo, at)
end

local function flush_delayed_sends()
-- Dispatch any <send> whose time has come
   while true do
      local sendinfo = delay_pop()
      if not sendinfo then return end
      local element = sendinfo.element
      local scxml = element._root
      if scxml._sendinfo then --<send> element:  delete entry for this message 
         scxml._sendinfo[sendinfo.sendid] = nil
      end
      delete_dynamic_id(element, sendinfo.sendid)
      if sendinfo.cancelled then return end
      if Sessions[scxml._sessionid]~=scxml then return end -- the sender exited
      dispatch_send(sendinfo)
   end
end

-------------------------------------------------------------------------------
-- Invoke processor
-------------------------------------------------------------------------------

local callmesoon -- call trigger() as soon as possible if this is true

local function create(sessionid, statechart, start, invokeinfo)
-- Validates a statechart given as a Lua table, compiles all its executable contents
-- and builds the associated meta information needed to execute the statechart.
-- The passed statechart is not altered (a validated version of the statechart is
-- created for internal use, containing all the metadata ready to be used in a session.)
   if statechart.tag~='scxml' then error('not an scxml element') end
   if type(sessionid)~='string' then error("missing or invalid sessionid") end
   if Sessions[sessionid] then error("session id '"..sessionid.."' is in use") end
   if invokeinfo then
      -- @@ sanitize invokeinfo
   end
   -- make a deep copy of the original statechart and validate it
   local scxml = copy_statechart(statechart)
   scxml._ENV = new_env()
   scxml._sessionid = sessionid
   Sessions[scxml._sessionid] = scxml
   Nsessions = Nsessions + 1
   validate_statechart(scxml, invokeinfo)
   if start then start_session(scxml) end
   callmesoon = true -- this is relevant only for create() within callback
end

local function start(sessionid) --@@ also pause/resume?
   local scxml = find_session(sessionid)
   if scxml._running then return end -- running or done: do nothing
   start_session(scxml)
end

local function delete_session(sessionid)
   local scxml = find_session(sessionid)
   Sessions[sessionid] = nil
   Nsessions = Nsessions - 1
end


local CANCEL_EVENT ='@cancel.session'
local function is_cancel_event(ev) return ev.name == CANCEL_EVENT end

local function cancel(sessionid)
   local scxml = Sessions[sessionid]
   if not scxml then return end -- already cancelled or done?
   if not scxml._running then -- just delete it abruptly
      delete_session(sessionid)
   else
      send_event(scxml, {name=CANCEL_EVENT, type='external'})
      -- sends a special external event, requesting cancellation
      -- (usually on behalf of the parent session if this is an invoked session.)
      -- This event will not trigger any transition but will cause the session to exit
      -- and be deleted.
   end
end

local function document_order(a, b) return a._eix < b._eix end

local function active_states(sessionid)
   local scxml = find_session(sessionid)
   local t = {}
   for _, s in pairs(scxml._activestates:sort(document_order)) do t[#t+1] = s.id end
   return t
end

local function is_active(sessionid, stateid)
   local scxml = find_session(sessionid)
   local s = scxml._idmap[stateid]
   if not s then return false end
   return scxml._activestates:ismember(s)
end

local function get_env(sessionid)
   local scxml = Sessions[sessionid]
   return scxml and scxml._ENV or nil
end

local function trigger()
   callmesoon = false
   flush_delayed_sends()
   for _, scxml in pairs(Sessions) do
      if scxml._running then -- running or done
         loop_iteration(scxml)
         callmesoon = callmesoon or scxml._macrostep or #scxml._extqueue>0
      end 
   end
   return Nsessions > 0 and (callmesoon and now() or delay_tnext()) or nil
end

-------------------------------------------------------------------------------

local function open(moonsc_, internal_)
   moonsc, internal = moonsc_, internal_
   moonsc.add_ioprocessor = add_ioprocessor
   moonsc.generate_sessionid = generate_sessionid
   moonsc.create = create
   moonsc.cancel = cancel
   moonsc.start = start
   moonsc.send = send
   moonsc.raise = raise
   moonsc.trigger = trigger
   moonsc.active_states = active_states
   moonsc.is_active = is_active
   moonsc.get_env = get_env
   moonsc.set_error_callback = function(func) error_callback=func end
   moonsc.set_send_callback = function(func) send_callback=func end
   -- get the functions for delay sends and hide them from the user
   delay_push = moonsc.delay_push;  moonsc.delay_push = nil
   delay_pop = moonsc.delay_pop;  moonsc.delay_pop = nil
   delay_tnext = moonsc.delay_tnext;  moonsc.delay_tnext = nil
   delay_reset = moonsc.delay_reset;  moonsc.delay_reset = nil
   now = moonsc.now
   internal.delete_session = delete_session
   internal.set_event = set_event
   internal.set_system_variables = set_system_variables
   internal.raise_event = raise_event
   internal.is_cancel_event = is_cancel_event
   internal.find_session = find_session
   internal.error_execution = error_execution
   internal.error_noaction = error_noaction
   internal.delay_send = delay_send
   internal.dispatch_send = dispatch_send
   internal.ioprocessor_supported = ioprocessor_supported
   internal.is_readonly = is_readonly
end


local function init(internal)
   start_session = internal.start_session
   loop_iteration = internal.loop_iteration
   copy_statechart = internal.copy_statechart
   validate_statechart = internal.validate_statechart
   new_env = internal.new_env
   path = internal.path
   delete_dynamic_id = internal.delete_dynamic_id
end

return { open = open, init = init }

