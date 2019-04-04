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
-- imported functions
local delete_session, set_event, set_system_variables, is_cancel_event
local list = require("moonsc.list")
local table_concat = table.concat
local fmt = string.format

local exit_callback, trace_callback

-- Compare functions for sorting elements
-- document_order = the order in which the elements occurred in the original document.
-- entry_order    = the order in which states are entered (ancestors precede descendants,
--                  with document order being used to break ties).
-- exit_order     = the order in which states are exited (descendants precede ancestors,
--                  with reverse document order being used to break ties).
-- (Note: since ancestors precede descendants, entry_order is equivalent to document order
-- and exit_order is equivalent to reverse document order.)
local function document_order(a, b) return a._eix < b._eix end
local entry_order = document_order
local function exit_order(a, b) return a._eix > b._eix end

local function idstr(element_list)
-- Returns a string with the ids of the elements in element_list, sorted in doc order.
   local tt = element_list:sort(document_order)
   local t = {}
   for _, s in pairs(tt) do t[#t+1] = s.id end
   return '{'..table_concat(t, ',')..'}'
end

--------------------------------------------------------------------------------
-- The 'current' session stack
--------------------------------------------------------------------------------

local CurrentStack = {}

local Current, SessionId, Active, InvokeStates, HistoryValue 

local function set_current(scxml)
-- Sets scxml as the current session (ie the one we're currently acting on).
   if not scxml then
      Current = nil
      return
   end
   Current = scxml
   SessionId = scxml._sessionid
   Active = scxml._activestates
   InvokeStates = scxml._invokestates
   HistoryValue = scxml._historyvalue
   set_system_variables(scxml)
end

local function switchto(scxml)
-- Sets scxml as the current session (ie the one we're currently acting on).
   -- push the old one on the stack
   if Current then CurrentStack[#CurrentStack+1] = Current end
   set_current(scxml)
end


local function switchback()
   local scxml = CurrentStack[#CurrentStack]
   if scxml then CurrentStack[#CurrentStack]=nil end
   set_current(scxml)
end

--------------------------------------------------------------------------------
-- Transition domain
--------------------------------------------------------------------------------

local function effective_targets(t)
-- Returns the list of effective targets for the transition t, which comprises
-- the specified targets with any history pseudo-state dereferenced
   local targets = list()
   for _, s in pairs(t._target) do
      if s.tag=='history' then
         -- instead of s (which is a pseudo-state) insert its stored state
         -- configuration or, if the parent state was never entered before,
         -- the default stored configuration
         local historyvalue = HistoryValue[s]
         targets:append(historyvalue and historyvalue or effective_targets(s._transition))
      else -- s is a proper state, so add it
         targets:add(s)
      end
   end
   return targets
end

local function transition_domain(t)
-- Returns the transition domain and the list of effective targets for the transition t
   local source, targets = t._source, effective_targets(t)
   if t.type=='internal' and source.tag~='parallel' and source._is_ancestor_of_all(targets) then
      return source, targets
   else -- external: the transition domain is the LCCA of source and targets
      for _, s in pairs(source._lineage) do
         if s.tag~='parallel' and s._is_ancestor_of_all(targets) then return s, targets end
      end
   end
   -- this point should be reached only if t is <scxml>.<initial>.<transition>
   return t._root, targets
end

--------------------------------------------------------------------------------
-- Exit states and entry states
--------------------------------------------------------------------------------
-- In the functions that follow, tset is always a list of transitions.

local function compute_exit_set(tset)
-- Returns the set of states that will be exited when taking the transitions in tset.
   local domains = {} -- transition domains for tset
   for _, t in pairs(tset) do
      -- skip targetless transitions, since they don't exit states
      if #t._target > 0 then domains[#domains+1] = transition_domain(t) end
   end
   -- All active states that are descendants of any transition domain will be exited:
   local exitset = list()
   for _, s in pairs(Active) do
      for _, td in ipairs(domains) do
         if td._is_ancestor_of(s) then exitset:add(s) break end
      end
   end
   return exitset   
end

local add_ancestors -- forward declaration

local function add_descendants(s, entryset, defentry, dht)
-- Adds to entryset the state s and any descendant that will be entered when entering s.
   if s.tag=='history' then
      -- s is a history pseudo-state, so we dereference it, adding either the historyvalue
      -- associated with it, or its default target (defined by its contained transition).
      -- Since the states contained in the historyvalue may not be immediate descendants
      -- of parent we also add add any ancestors between them and and parent.
      local parent = s._parent -- the state containing the <history> element s
      local historyvalue = HistoryValue[s]
      if historyvalue then
         for _, s1 in pairs(historyvalue) do
            add_descendants(s1, entryset, defentry, dht)
         end
         for _, s1 in pairs(historyvalue) do
            add_ancestors(s1, parent, entryset, defentry, dht)
         end
      else -- default stored configuration
         historyvalue = s._transition._target
         dht[parent] = s._transition
         for _, s1 in pairs(historyvalue) do
            add_descendants(s1, entryset, defentry, dht)
         end
         for _, s1 in pairs(historyvalue) do
            add_ancestors(s1, parent, entryset, defentry, dht)
         end
      end
   else -- s is a proper state element: add it together with the relevant descendants
      entryset:add(s)
      if s._isatomic then
         -- it has no descendants
      elseif s.tag == 'parallel' then
         -- s is a parallel state so all of its children must be entered. Recursively call
         -- this function on any child that doesn't have descendants in entryset already.
         for _, s1 in pairs(s._substates) do
            if not s1._is_ancestor_of_some(entryset) then 
               add_descendants(s1, entryset, defentry, dht)
            end
         end
      else
         -- s is a compound state: add it to defentry and recursively call this
         -- function on its default initial state(s) to add also it and any of its
         -- descendants that must be entered:
         defentry:add(s)
         local target = s._initial._transition._target
         for _, s1 in pairs(target) do
            add_descendants(s1, entryset, defentry, dht)
         end
         -- Since the default initial states may not be children of s, also
         -- add any ancestors between them and s:
         for _, s1 in pairs(target) do
            if s1.tag ~= 'history' then --@@ not sure about this
               add_ancestors(s1, s, entryset, defentry, dht)
            end
         end
      end
   end
end

add_ancestors = function(s, anc, entryset, defentry, dht)
-- Add to entryset any ancestors of s, up to anc exclusive, since these must all be entered
-- when s is. If any of these ancestors is a parallel state, add also its children and any
-- of their descendants that must be entered too.
   for _, ss in pairs(s._lineage) do
      if ss == anc then break end
      entryset:add(ss)
      if ss.tag=='parallel' then
         for _, s1 in pairs(ss._substates) do
            if not s1._is_ancestor_of_some(entryset) then
               add_descendants(s1, entryset, defentry, dht)
            end
         end
      end
   end
end

local function compute_entry_set(tset)
-- Computes and returns:
-- entryset = the set of states that will be entered when taking the transitions in tset.
-- defentry = the set of states whose default initial states are entered,
-- dht = a table containing any history transitions whose content must be executed
--       (dht[h]=t where h is an history element and t is its transition, or nil if
--       it must not be executed)
   local entryset, defentry, dht = list(), list(), {}
   for _, t in pairs(tset) do
      -- Add all the specified targets and, for those that are not atomic, add all
      -- of their (default) descendants until we reach one or more atomic states.
      for _, s in ipairs(t._target) do
         add_descendants(s, entryset, defentry, dht)
      end
      -- Add any ancestors that will be entered within the domain of the transition.
      -- (Ancestors outside of the transition domain are not exited.)
      local domain, targets = transition_domain(t)
      for _, s in pairs(targets) do
         add_ancestors(s, domain, entryset, defentry, dht)
      end
   end
   return  entryset, defentry, dht
end

local function exit_states(tset)
   local exitset = compute_exit_set(tset):sort(exit_order)
   if trace_callback then
      trace_callback(SessionId, "exit states "..idstr(exitset))
   end
   for _, s in pairs(exitset) do
      -- Any pending invoke would be immediately cancelled, so don't do them:
      InvokeStates:delete(s)
      if s._history then -- store history value before exiting
         for _, h in pairs(s._history) do HistoryValue[h] = h._value() end
      end
   end

   for _, s in pairs(exitset) do
      for _, onexit in pairs(s._onexit) do onexit._execute() end
      for _, invoke in pairs(s._invoke) do invoke._cancel() end
      Active:delete(s) -- remove from the current configuration
   end
end

local exit_session -- forward decl.

local function enter_states(tset)
   local entryset, defentry, dht = compute_entry_set(tset)
   if trace_callback then
      trace_callback(SessionId, "enter states "..idstr(entryset))
   end
   for _, s in pairs(entryset:sort(entry_order)) do
      Active:add(s)
      InvokeStates:add(s) -- ie when the macrostep ends, do any pending invoke for s
      -- Binds variables, if late binding and this is the first time s is entered:
      if s._datamodel then s._datamodel._execute() end
      -- Execute any onentry for this state:
      for _, onentry in pairs(s._onentry) do onentry._execute() end

      -- If the initial state for s is being entered by default, execute any
      -- executable content in the initial transition:
      if defentry:ismember(s) then s._initial._transition._execute() end

      -- If a history state in s was the target of a transition, and s was not
      -- entered before, execute the content inside the history state's default
      -- transition:
      if dht[s] then dht[s]._execute() end

      if s.tag=='final' then
         if s._parent.tag=='scxml' then -- we have reached a top-level final state
            exit_session('done') -- done, stop processing
         else
            s._done() -- generate the 'done' event
         end
      end
   end
   if trace_callback and #Active>0 then
      trace_callback(SessionId, "active states "..idstr(Active))
   end
end

--------------------------------------------------------------------------------
-- Transitions selection
--------------------------------------------------------------------------------

local function remove_conflicts(tset)
-- Filter tset keeping only the transitions with higher priority if there are conflicts.
   local  newset = list() -- the conflict-free set that will be returned
   -- Sort the transitions in the order of the states that selected them
   for _, t1 in pairs(tset) do
      -- Test t1 against the transitions already added in the newset:
      local t1_preempted = false
      local exit_set1 = compute_exit_set(list(t1))
      local remset = list() -- transitions to remove
      for _, t2 in pairs(newset) do
         local exit_set2 = compute_exit_set(list(t2))
         if exit_set1:intersects(exit_set2) then -- there is a conflict between t1 and t2.
            -- t1 preempts t2 if t1's source state is a descendant of t2's source state,
            -- otherwise t2 preempts t1 because it was selected in an earlier state in
            -- document order
            if t2._source._is_ancestor_of(t1._source) then
               remset:add(t2)
            else
               t1_preempted = true
               break -- there is no need to test further: just don't add t1 to newset
            end
         end
      end
      if not t1_preempted then -- remove all those preempted (if any) and add t1
         for _, t2 in pairs(remset) do newset:delete(t2) end
         newset:add(t1)
--    else 
--       t1_preempted, do nothing (t2 is already in newset)
      end
   end
   return newset
end

local function enabled_transitions(name)
-- Returns the set of transitions enabled in the current configuration, by an event
-- with the given name, or nil if none (pass name=nil for eventless transitions)
   local tset = list()
   for _, s in pairs(Active:sort(document_order)) do
      if s._isatomic then
      -- Search for an enabled transition in the lineage, starting from the atomic
      -- state and moving upwards until one is found, then add it to the set and
      -- repeat with the next atomic state.
      -- (Note that if more than one transition could be enabled in the same state,
      -- only the first in document order is enabled).
         local et -- enabled transition
         for _, t in pairs(s._transition) do if t._match(name) then et = t break end end
         if not et then -- search up the lineage
            for _, ss in pairs(s._lineage) do
               for _, t in pairs(ss._transition) do if t._match(name) then et = t break end end
               if et then break end
            end
         end
         if et then tset:add(et) end -- else no transition is enabled on this lineage
      end
   end
   if #tset==0 then return nil end
   return remove_conflicts(tset)
end

--------------------------------------------------------------------------------
-- Session termination
--------------------------------------------------------------------------------

exit_session = function(reason)
-- Exits the current SCXML process by exiting all active states.
   local exitset = Active:sort(exit_order)
   for _, s in pairs(exitset) do
      for _, onexit in pairs(s._onexit) do onexit._execute() end
      for _, invoke in pairs(s._invoke) do invoke._cancel() end
      Active:delete(s)
      if s.tag=='final' and s._parent.tag=='scxml' then s._done() end
      -- The machine is in a top-level final state, so generate a 'done' event.
      -- (Note that in this case, the final state will be the only active state.)
   end
   if trace_callback then
      trace_callback(SessionId, "session stops ("..reason..")")
   end
   if exit_callback then exit_callback(SessionId, reason, Current._invokeinfo) end
   delete_session(SessionId)
end

--------------------------------------------------------------------------------
-- Main loop iteration
--------------------------------------------------------------------------------

local function trace_queued_events()
   if #Current._intqueue > 0 then
      local t = {}
      for _, ev in pairs(Current._intqueue) do t[#t+1] = "'"..ev.name.."'" end
      trace_callback(SessionId, fmt("queued internal events: %s", table.concat(t, ', ')))
   end
   if #Current._extqueue > 0 then
      local t = {}
      for _, ev in pairs(Current._extqueue) do t[#t+1] = "'"..ev.name.."'" end
      trace_callback(SessionId, fmt("queued external events: %s", table.concat(t, ', ')))
   end
end

local function microstep(tset)
-- Processes a set of transitions in lock-step.
-- ev = an event (eventinfo table)
   exit_states(tset)
   for _, t in pairs(tset) do
      if trace_callback then
         trace_callback(SessionId, "transition "..
               t._source.id.."->{"..table_concat(t._targetids,',').."}")
      end
      t._execute()
   end
   enter_states(tset)
end

local function loop_iteration_(scxml)
   
   -- if trace_callback then trace_queued_events() end --@@ debug only
   if not Current._macrostep then -- poll for external events
      local ev = Current._extqueue:pop()
      if not ev then return end -- empty
      if is_cancel_event(ev) then -- cancelled by parent session
         if trace_callback then
            trace_callback(SessionId, "cancelled")
         end
         scxml._dont_send = true --@@ see test252
         exit_session('cancelled')
         return
      end
      if trace_callback then
         trace_callback(SessionId, "processing external event '"..ev.name.."'")
      end
      Current._macrostep = true
      set_event(Current, ev)
      -- Preprocess the event for states that have executed any <invoke>.
      for _, s in pairs(Active) do
         for _, invoke in pairs(s._invoke) do
            invoke._check_done_event(ev) -- check if this is the 'done.invoke.id' event
            invoke._finalize(ev)
            invoke._autoforward(ev)
         end
      end
      local tset = enabled_transitions(ev.name)
      if tset then microstep(tset) end
   end

   -- process eventless transitions, if any
   local tset = enabled_transitions(nil)
   if tset then
      if trace_callback then
         trace_callback(SessionId, "processing null event")
      end
      set_event(Current, nil)
      microstep(tset) 
      return 
   end

   -- process the next internal event, if any
   local ev = Current._intqueue:pop()
   if ev then
      if trace_callback then
         trace_callback(SessionId, "processing internal event '"..ev.name.."'")
      end
      set_event(Current, ev)
      local tset = enabled_transitions(ev.name)
      if tset then microstep(tset) end
      return 
   end

   Current._macrostep = false
   -- Execute any <invoke> element
   while true do
      local s = InvokeStates:pop()
      if not s then
         break end
      for _, invoke in pairs(s._invoke) do 
         invoke._execute()
         Current._macrostep = true -- invoke may cause further internal events
      end
   end
end

local function start_session_(scxml)
   if trace_callback then
      trace_callback(SessionId, "session starts")
   end
   scxml._running = true -- running
   scxml._early_binding()
   if scxml._globalscript then scxml._globalscript._execute() end
   enter_states(list(scxml._initial._transition))
end


local function loop_iteration(scxml)
   switchto(scxml)
   pcall(loop_iteration_, scxml)
   switchback()
end

local function start_session(scxml)
   switchto(scxml)
   pcall(start_session_, scxml)
   switchback()
end


--------------------------------------------------------------------------------

local function open(moonsc_, internal_)
   moonsc, internal = moonsc_, internal_
   moonsc.set_exit_callback = function(func) exit_callback = func end
   moonsc.set_trace_callback = function(func) trace_callback = func end
   internal.start_session = start_session
   internal.loop_iteration = loop_iteration
end

local function init(internal)
   delete_session = internal.delete_session
   set_event = internal.set_event
   set_system_variables = internal.set_system_variables
   is_cancel_event = internal.is_cancel_event
end

return { open = open, init = init }

