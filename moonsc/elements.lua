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
local fifo = require("moonsc.fifo")
local list = require("moonsc.list")
-- imported functions:
local err, valid_tag, isstate, isstate_or_history, raise_event, now
local error_execution, error_noaction, delay_send, dispatch_send, chunk
local is_readonly, ioprocessor_supported, css2time, split, event_match
-- callbacks:
local data_callback, script_callback, content_callback
local invoke_callback, cancel_callback, log_callback
-- shortcuts:
local string_match, string_gmatch = string.match, string.gmatch
local table_insert, table_concat = table.insert, table.concat

local function donothing() end
local function alwaystrue() return true end

local function check_attributes(element, optional, mandatory, atleastoneof, onlyoneof)
-- Preliminary checks on the attributes of element
   for _, attr in ipairs(optional) do
      local t = type(element[attr])
      if t ~= 'nil' and t ~= 'string' then
         err(element, "attribute %s in <%s> is not a string", attr, element.tag)
      end
   end
   for _, attr in ipairs(mandatory) do
      local t = type(element[attr])
      if t == 'nil' then err(element, "missing %s in <%s>", attr, element.tag) end
      if t ~= 'string' then err(element, "attribute %s in <%s> is not a string", attr, element.tag) end
   end
   -- check that at least one of alternative fields are present:
   for _, alt in ipairs(atleastoneof) do
      local present = false
      for _, attr in ipairs(alt) do if element[attr] then present = true break end end
      if not present then 
         err(element, "<%s> must contain at least one of: %s", element.tag, table_concat(alt, ', '))
      end
   end
   -- check that only one of mutually exclusive fields are present:
   for _, alt in ipairs(onlyoneof) do
      local present = false
      for _, attr in ipairs(alt) do
         if element[attr] then 
            if present then 
               err(element, "<%s> can contain only one of: %s", element.tag, table_concat(alt, ', '))
            end
            present = true
         end
      end
   end
end

-------------------------------------------------------------------------------
-- Element index in document order (eix)
-------------------------------------------------------------------------------

local function assign_eix(element)
-- Returns the next free eix in the statechart
-- Increasing indices are assigned in document order, starting from <scxml>=1
   local scxml = element._root
   if not scxml._nexteix then
      scxml._nexteix = (function()
         local eix=0
         return function() eix = eix+1; return eix end
      end)()
   end
   return scxml._nexteix()
end

-------------------------------------------------------------------------------
-- IDs
-------------------------------------------------------------------------------

local function generate_id(element)
-- Returns a new automatic id, guaranteed to be unique within the statechart
   local scxml = element._root
   if not scxml._autoid then -- create the id generator for this session
      scxml._autoid = (function() local i = 0 return
         function(element)
            i=i+1
            local id = "autoid"..i
            if element.tag=='invoke' then return element._parent.id.."."..id end
            return id
         end
      end)()
   end
   return scxml._autoid(element)
end

local function register_id(element)
-- Registers the element's id in the root's id-to-element map and returns it.
-- If the element lacks an id, assigns it an automatic one.
   local idmap = element._root._idmap
   local id = element.id or generate_id(element)
   if idmap[id] then err(element, "duplicated id '"..id.."'") end
   idmap[id] = element
   return id
end

local function check_id_or_idlocation(element)
-- For <send> and <invoke> only. Checks if the element has the id or the
-- idlocation attributes, and adds the _dynamic_id function to set the id value
-- at evaluation time in the variable specified by idlocation (if any).
   if element.id then
      register_id(element)
   else -- Dynamic id.
      -- _dynamic_id(id) sets idlocation=id in the session's _ENV (if needed)
      -- The id must be generated and registered at evaluation time, and
      -- unregistered at the end of the element execution:
      -- for <send>, this is when the message is dispatched or canceled,
      -- for <invoke>, this is when the invoke is done or canceled because
      -- the parent state is exited.
      element._dynamic_id = element.idlocation and
            chunk(element, element.idlocation.."=select(2, ...)") or  function() end
   end
end

local function generate_dynamic_id(element)
-- For <send> and <invoke> only. To be called at the beginning of an execution of
-- the element, if needed creates the id dynamically and registers it.
   if element.id then return element.id end -- not dynamic
   -- generate an automatic id, register it in idmap, and set the value in idlocation:
   local id = register_id(element)
   element._dynamic_id(nil, id)
   return id
end

local function delete_dynamic_id(element, id)
-- For <send> and <invoke> only, Deletes the id if it is dynamic.
-- To be called only at the end of the element execution.
   local idmap = element._root._idmap
   -- assert(idmap[id]==element)
   if element.id then return end -- not a dynamic id
   idmap[id]=nil
end

-------------------------------------------------------------------------------
-- STATECHART VALIDATION
-------------------------------------------------------------------------------
-- The validation process adds meta information to the original elements, in
-- additional attributes having names that start with '_'.
-- The following 'meta attributes' are added to all elements:
-- _root      = the root <scxml> element
-- _parent    = the enclosing element (= nil for <scxml>)
-- _eix       = element index defining the document ordering
--
-- The following are added only to element of state types, ie <scxml>, <state>,
-- <parallel>, and <final>:
-- _substates   = list of immediate children that are states, in document order
-- _descendants = list of all descendant states, in document order
-- _lineage     = the lineage, in ancestry order, from the parent inclusive up to
--                <scxml> inclusive (thus the linage for <scxml> is an empty list)
-- _isdone()    = returns true if the state is done, false otherwise.
-- _is_ancestor_of(s) = returns true if the state is an ancestor of the state s
-- _is_ancestor_of_some(states), _is_ancestor_of_all(states) = return true if the
--           state is an ancestor of some or of all the states in the passed list
--
-- All 'executable' elements have a _execute() attribute, that when called executes
-- the element contents in the dedicated _ENV of the session.
-- An _execute() function must obey these rules:
--  E1) Do its stuff in protected mode (pcall).
--  E2) Return true if no errors occur during its execution, false otherwise.
--  E3) Send back an error event if it detects an error directly.
--  E4) Don't send beck any error event if it detects an error indirectly,
--      ie by a false returned by a nested _execute() (in this case, the error
--      event has already been sent).
--
-- Other meta attributes/functions are tag-specific described with the validation
-- function for elements of that tag.

local function copy_statechart(element, parent)
-- Deep copies a raw statechart (ie. in the form provided by the user), making some
-- preliminary checks and adding the _parent and _root attributes to all elements.
-- The returned copy must be passed to validate() for the subsequent passes.
   local el = {}
   el.tag = element.tag
   el.text = element.text
   el._parent = parent -- =nil for root
   el._root = parent and parent._root or el
   for k, v in pairs(element) do if type(k)=='string' then el[k] = v end end
   for i, child in ipairs(element) do
      if type(child)~='table' then err(el, "child element %d is not a table", i) end
      local tag = child.tag
      if not tag then err(el, "missing tag in child %d", i) end
      if not valid_tag(tag) then err(el, "invalid tag '%s' in child %d", tag or '???', i) end
      el[i] = copy_statechart(element[i], el)
   end
   return el
end

local validate_func = {} -- tag-specific validation functions (indexed by tag)

local function validate(element, parent, counters)
-- parent = the parent of this element, or nil if this is <scxml>
-- counters is a table containing per-tag counters of the parent's children
-- counters.tag = the maximum no. of parent's children of the <tag> type, or nil
--                if parent does not admit <tag> children
   if counters then
      -- Check and update the parent's counters of children of particular tags.
      -- Note: any check for missing mandatory children or for mutually exclusive
      -- children must be done in the parent's validate_func.
      local tag = element.tag
      if not counters[tag] then err(parent, "<%s> cannot have <%s> child", parent.tag, tag)
      elseif counters[tag] == 0 then err(parent, "too many <%s> children for <%s>",tag, parent.tag)
      else -- counters[tag] > 0
         counters[tag] = counters[tag]-1
      end
   end
   -- Note: we assign eix here and not in the preliminary pass because <initial> elements
   -- may be added to state elements if missing or to replace 'initial' attributes:
   element._eix = assign_eix(element)
   validate_func[element.tag](element)
end

local function validate_statechart(scxml, invokeinfo)
   scxml._invokeinfo = invokeinfo
   validate(scxml)
end

local function no_children(element) -- checks that element has no children
   for _, child in ipairs(element) do validate(child, element, {}) end
end

local N = math.huge -- meaning 'zero or more' in element counters

local function executable_content() -- returns the counters for executable content
   return { ['if']=N, foreach=N, log=N, assign=N, script=N, raise=N, send=N, cancel=N }
end

local function add_lineage(element)
-- Adds the _lineage list to a state element
   local lineage = list()
   local s = element._parent
   while s do lineage:add(s); s = s._parent end
   element._lineage = lineage
end

local function add_descendants(element, descendants)
-- Add the _descendants list to a state element. Also adds some useful predicates.
   local d = descendants or list()
   for _, child in ipairs(element) do
      if isstate(child) then
         d:add(child)
         add_descendants(child, d)
      end
   end
   if not descendants then
      element._descendants = d
      -- Add predicates
      element._is_ancestor_of = function(s) return d:ismember(s) end
      element._is_ancestor_of_some = function(states)
            for _, s in pairs(states) do if d:ismember(s) then return true end end
            return false
         end
      element._is_ancestor_of_all = function(states)
            for _, s in pairs(states) do if not d:ismember(s) then return false end end
            return true
         end
   end
end

local function add_substates(element)
-- Adds the _substates list to a state element
   local substates = list()
   for _, child in ipairs(element) do
      if isstate(child) then substates:add(child) end
   end
   element._substates = substates
end

local function add_initial(element)
-- Adds the <initial> children  to a state element, if it is missing or if it is
-- given as an attribute. Must be called after add_substates().
   if element.tag~='scxml' and #element._substates==0 then
      element._isatomic=true return
   end
   for _, child in ipairs(element) do
      if child.tag=='initial' then -- already in
         if element.tag=='scxml' then
            err(element, "<scxml> cannot have <initial> child")
            -- Note that the author cannot insert a <initial> child in <scxml>,
            -- but we do add one in this function, as a replacement of the
            -- 'initial' attribute or as the default first state element.
         end
         return
      end
   end
   -- If element has an initial attribute turn it into an <initial> children,
   -- otherwise add an <initial> children whose <transition> targets the first
   -- child state in document order:
   local target = element['initial']
   if not target then
      local first = element._substates:head()
      -- assure that it has an id assigned to it:
      if not first.id then first.id = generate_id(element) end
      target = first.id
   end
   local transition = { tag='transition', target=target }
   local initial = {tag='initial', [1]=transition}
   initial._parent = element
   initial._root = element._root
   transition._parent = initial
   transition._root = element._root
   element[#element+1] = initial
end

local function check_namelist(element)
-- Checks the 'namelist' attribute and returns either nil (if absent or empty)
-- or a function that when called returns a table t where t[name]=value.
   if not element.namelist then return nil end
   local namelist = element.namelist and split(element.namelist) or nil
   if #namelist==0 then return nil end
   local value = {}
   for i, name in ipairs(namelist) do
      value[i] = chunk(element, "return "..name)
   end
   return function()
      local t = {}
      --@@ what is 'valid' here? Do the names have to be datamodel variables? see test554
      for i, name in ipairs(namelist) do t[name]=value[i]() end
      return t
   end
end

local function fix_transition_targets(element, parent)
-- Checks that the target ids in all <transition> elements correspond to valid states
-- and replace them with the corresponding states.
-- Note that we need to do this in an after-pass because when validating a <transition>,
-- its target states may not be added to the idmap yet.
   if element.tag == 'transition' then
      local idmap = element._root._idmap
      local target = element._targetids
      local granpa, history = parent._parent, false
      local initial = parent.tag == 'initial'
      if parent.tag == 'history' then history = parent.type end
      for i, id in pairs(target) do
         local s = idmap[id]
         if not s then err(element, "unknown target state '%s'", id) end
         if not isstate_or_history(s) then err(element, "'%s' is not a state element", id) end
         -- if parent is <history>, check that transition targets are valid states
         -- (this depends on history type being shallow or deep)
         if initial then
            if not s.tag=='history' and not granpa._is_ancestor_of(s) then
               err(element, "invalid target '%s' in initial <transition>", id)
            end
         elseif not history then -- parent is <parallel> or <state>
            -- any state is a valid target
         elseif history == 'shallow' then
            if not granpa._substates:ismember(s) then
               err(element, "invalid target '%s' in shallow history <transition>", id)
            end
         elseif history == 'deep' then
            if not granpa._is_ancestor_of(s) then
               err(element, "invalid target '%s' in deep history <transition>", id)
            end
         end
         -- target state is valid: replace the id with the state itself
         element._target[i] = s
      end
   end
   for _, child in ipairs(element) do fix_transition_targets(child, element) end
end

-------------------------------------------------------------------------------
-- <SCXML> (state)
-------------------------------------------------------------------------------
-- _sessionid  = unique session identifier (to be used, eg, as <send>.target)
-- _invokeinfo = the invokeinfo struct if this is an invoked child session
-- _idmap     = id-to-element map for this session
-- _autoid    = generator of automatic ids for this session
-- _ENV       = the environment dedicated to this session
-- _lineage   = the lineage (empty list)
-- _substates = list of children states
-- _descendants = list of all descendant states (ie all states)
-- _initial   = the child <initial>
-- _script    = the child <script> (opt)
-- _datamodel = the child <datamodel> (opt)
-- _childsession = table where _childsession[invokeid] = sessionid of child
-- The 'global' variables (as per the SCXML spec's algorithm):
-- _activestates = list of active states (the current configuration)
-- _invokestates = list of states whose invocations must be performed
-- _intqueue     = internal events to be processed (fifo)
-- _extqueue     = external events to be processed (fifo)
-- _historyvalue = stored history configurations (_historyvalue[h] is the list
--                 of states to enter for the <history> element h)
validate_func['scxml'] = function(element)
   local element = element
   element._idmap = {}
-- element.name = element.name or '???'
   element.version = element.version or "1.0"
   if element.version ~= "1.0" then err(element, "invalid version in <scxml>") end
   element.datamodel = element.datamodel or 'lua'
   if element.datamodel ~= 'lua' then err(element, "invalid datamodel") end
   element.binding = element.binding or 'early'
   if element.binding ~= 'early' and element.binding ~= 'late' then
      err(element, "invalid binding")
   end
   check_attributes(element, 
      { 'initial', 'name', 'version', 'datamodel', 'binding' }, -- optional
      {}, -- mandatory
      {}, -- atleastoneof
      {}  -- onlyoneof
   )
   add_lineage(element)
   add_descendants(element)
   add_substates(element)
   add_initial(element) -- note that this creates an <initial> child
   element._datamodels = {} -- list of all datamodel elements, in doc order
   element._sendinfo = {} -- ongoing delayed sends, indexed by sendid
   element._childsession = {}
   element._invokestates = list()
   element._intqueue = fifo()
   element._extqueue = fifo()
   element._historyvalue = {}
   element._transition = list() -- empty
   element._running = false
   element._macrostep = true -- true if ongoing macrostep
   element._activestates = list()
   -- Add the '_x' system variable, the invoke information (if this is an invoked session),
   -- the 'In()' predicate and a few platform-dependent utilities.
   local env = element._ENV
   local activestates = element._activestates -- current configuration
   local idmap = element._idmap
   env['In'] = function(stateid)
      local s = idmap[stateid]
      if not s then return false end
      return activestates:ismember(s)
   end
   env['Now'] = moonsc.now
   env['Since'] = moonsc.since
   env._x = {} -- for platform-dependent system variables
   if element._invokeinfo then -- invoked session
      env._invokeid = element._invokeinfo.invokeid
      env._x.invokeinfo = element._invokeinfo
   end
   -- Validate children:
   local counters = { state=N, parallel=N, final=N, datamodel=1, script=1, initial=1 }
   -- Note that exactly 1 <initial> is present: the one generated by add_initial()
   for _, child in ipairs(element) do
      validate(child, element, counters)
      local tag = child.tag
      if tag=='script' then element._globalscript = child
      elseif tag=='initial' then element._initial = child
      elseif tag=='datamodel' then element._datamodel = child
      end
   end
   fix_transition_targets(element)
   element._early_binding = element.binding == 'late' and donothing
      or function()
            for _, datamodel in ipairs(element._datamodels) do
               if not datamodel._execute() then return false end
            end
            return true
         end
end

-------------------------------------------------------------------------------
-- <STATE> (state)
-------------------------------------------------------------------------------
-- _lineage   = the lineage
-- _substates = list of children states
-- _descendants = list of all descendant states
-- _initial   = the child <initial>
-- _datamodel = the child <datamodel> (opt)
-- _onentry, _onexit, _invoke, _transition, _history = lists of children
validate_func['state'] = function(element)
   local element = element
   check_attributes(element, 
      { 'id', 'initial' }, -- optional
      {}, -- mandatory
      {}, -- atleastoneof
      {}  -- onlyoneof
   )
   element.id = register_id(element)
   add_lineage(element)
   add_descendants(element)
   add_substates(element)
   add_initial(element)
   element._onentry = list()
   element._onexit = list()
   element._invoke = list()
   element._transition = list()
   element._history = list()
   local counters = { onentry=N, onexit=N, transition=N, initial=1, state=N,
                      parallel=N, final=N, history=N, datamodel=1, invoke=N }
   for _, child in ipairs(element) do
      validate(child, element, counters)
      local tag = child.tag
      if tag=='transition' then element._transition:add(child)
      elseif tag=='onentry' then element._onentry:add(child)
      elseif tag=='onexit' then element._onexit:add(child)
      elseif tag=='invoke' then element._invoke:add(child)
      elseif tag=='history' then element._history:add(child)
      elseif tag=='initial' then element._initial = child
      elseif tag=='datamodel' then element._datamodel = child
      end
   end

   element._isdone = function() -- it is done when any of its children is a done <final> state
      for _, s in pairs(element._substates) do
         if s.tag=='final' and s._isdone() then return true end
      end
      return false
   end
end

-------------------------------------------------------------------------------
-- <PARALLEL> (state)
-------------------------------------------------------------------------------
-- _lineage   = the lineage
-- _substates = list of children states
-- _descendants = list of all descendant states
-- _datamodel = the child <datamodel> (opt)
-- _onentry, _onexit, _invoke, _transition, _history = lists of children
validate_func['parallel'] = function(element)
   local element = element
   check_attributes(element, 
      { 'id' }, -- optional
      {}, -- mandatory
      {}, -- atleastoneof
      {}  -- onlyoneof
   )
   element.id = register_id(element)
   add_lineage(element)
   add_descendants(element)
   add_substates(element)
   element._onentry = list()
   element._onexit = list()
   element._invoke = list()
   element._transition = list()
   element._history = list()
   local counters = { onentry=N, onexit=N, transition=N, state=N, parallel=N,
                      history=N, datamodel=1, invoke=N }
   for _, child in ipairs(element) do
      validate(child, element, counters)
      local tag = child.tag
      if tag=='transition' then element._transition:add(child)
      elseif tag=='onentry' then element._onentry:add(child)
      elseif tag=='onexit' then element._onexit:add(child)
      elseif tag=='invoke' then element._invoke:add(child)
      elseif tag=='history' then element._history:add(child)
      elseif tag=='datamodel' then element._datamodel = child
      end
   end
   element._isdone = function() -- it is done when all its children are done
      for _, s in pairs(element._substates) do
         if not s._isdone() then return false end
      end
      return true
   end
end

-------------------------------------------------------------------------------
-- <FINAL> (state)
-------------------------------------------------------------------------------
-- _onentry, _onexit = lists of children
-- _done() = sends the needed done events
-- _isdone() = returns true if the state is active
validate_func['final'] = function(element)
   local element = element
   check_attributes(element, 
      { 'id' }, -- optional
      {}, -- mandatory
      {}, -- atleastoneof
      {}  -- onlyoneof
   )
   element.id = register_id(element)
   element._onentry = list()
   element._onexit = list()
   element._isatomic = true
   element._transition = list() -- empty list
   element._invoke = list() -- empty list
   add_lineage(element)
   add_descendants(element) --empty list
   element._substates = list() -- empty list
   local donedata -- the child <donedata>, or nil

   local counters = { onentry=N, onexit=N, donedata=1 }
   for _, child in ipairs(element) do
      validate(child, element, counters)
      local tag = child.tag
      if tag=='onentry' then element._onentry:add(child)
      elseif tag=='onexit' then element._onexit:add(child)
      elseif tag=='donedata' then donedata = child
      end
   end

   local scxml = element._root
   local parent = element._parent
   local granpa = parent._parent

   element._isdone = function() -- it is done when it is active
      return scxml._activestates:ismember(element)
   end

   local function get_donedata()
      if not donedata then return nil end
      local ok, data = pcall(donedata._value)
      if ok then return data end
      error_execution(element, data)
      return nil
   end

   local donefunc
   if parent.tag ~= 'scxml' then
      if granpa.tag == 'parallel' then
         donefunc = function()
            local data = get_donedata()
            raise_event(scxml, {name='done.state.'..parent.id, type='platform', data=data})
            if granpa._isdone() then
               raise_event(scxml, {name='done.state.'..granpa.id, type='platform'})
            end
         end
      else -- granpa is compound
         donefunc = function()
            local data = get_donedata()
            raise_event(scxml, {name='done.state.'..parent.id, type='platform', data=data})
         end
      end
   elseif parent._invokeinfo then
      -- This session is the result of an <invoke>, so send the 'done.invoke.id'
      -- event to the parent session.
      donefunc = function()
         local sendinfo = {
            element = element, -- for internal use only
            type = 'scxml',
            target = '#_parent',
            -- sendid = nil
            event = 'done.invoke.'..parent._invokeinfo.invokeid,
            data = get_donedata()
         }
         dispatch_send(sendinfo)
         -- don't generate other events after this (see 6.4.2):
         scxml._dont_send = true
      end
   end
   if donefunc then
      element._done = function()
         local ok, errmsg = pcall(donefunc)
         if not ok then return error_execution(element, errmsg) end
         return true
      end
   else
      element._done = donothing
   end
end

-------------------------------------------------------------------------------
-- <INITIAL> (pseudostate)
-------------------------------------------------------------------------------
-- _transition = the child <transition> (has exactly one)
validate_func['initial'] = function(element)
   local element = element
   -- check_attributes(element, {}, {}, {}, {})
   local counters = { transition=1 }
   for _, child in ipairs(element) do
      validate(child, element, counters)
      if not child.target then err(child, "missing target in initial <transition>") end
      if child.cond then err(child, "initial <transition> cannot have cond") end
      if child.event then err(child, "initial <transition> cannot have event") end
      element._transition = child
   end
   if counters.transition == 1 then err(element, "missing <transition>") end
end

-------------------------------------------------------------------------------
-- <HISTORY> (pseudostate)
-------------------------------------------------------------------------------
-- _transition = the child <transition> (has exactly one)
-- _value() = a function that returns the current history value, ie the list of
--            states that will be entered the next time the history pseudostate
--            will be entered.
validate_func['history'] = function(element)
   local element = element
   check_attributes(element, 
      { 'id', 'type' }, -- optional
      {}, -- mandatory
      {}, -- atleastoneof
      {}  -- onlyoneof
   )
   element.id = register_id(element)
   element.type = element.type or 'shallow'
   local parent = element._parent
   local active = element._root._activestates
   local f =  element.type == 'deep'
   if element.type == 'shallow' then -- all active immediate children of parent
      f = function(s) return s._parent == parent end
   elseif element.type == 'deep' then -- all active atomic descendants of parent
      f = function(s) return s._isatomic and parent._is_ancestor_of(s) end
   else
      err(element, "invalid history type")
   end
   element._value = function() return active:filter(f) end
   local counters = { transition=1 }
   for _, child in ipairs(element) do
      validate(child, element, counters)
      if not child.target then err(element, "missing target in history <transition>") end
      if child.cond then err(element, "history <transition> cannot have cond") end
      if child.event then err(element, "history <transition> cannot have event") end
      element._transition = child
   end
   if not element._transition then err(element, "missing <transition> in <history>") end
end

-------------------------------------------------------------------------------
-- <ONENTRY>, <ONEXIT> (executableblock)
-------------------------------------------------------------------------------
validate_func['onentry'] = function(element)
   local element = element
   -- check_attributes(element, {}, {}, {}, {})
   local counters = executable_content()
   for _, child in ipairs(element) do validate(child, element, counters) end
   element._execute = function()
      for _, c in ipairs(element) do
         if not c._execute() then return false end
      end
      return true
   end
end

validate_func['onexit'] = validate_func['onentry'] -- only the tag differs

-------------------------------------------------------------------------------
-- <TRANSITION> (executableblock)
-------------------------------------------------------------------------------
-- _target  = {state} or {}
-- _targetids  = {stateid} or {}
-- _source  = the enclosing <parallel> or <state>
-- _match(name) = transition-matches-event predicate (name=nil for NULL event)
validate_func['transition'] = function(element)
   local element = element
   check_attributes(element, 
      { 'event', 'cond', 'target', 'type' }, -- optional
      {}, -- mandatory
      {}, -- atleastoneof
      {}  -- onlyoneof
   )
   element.type = element.type or 'external'
   if element.type ~= 'external' and element.type ~= 'internal' then
      err(element, "invalid transition type")
   end
   if not (element.event or element.cond or element.target) then
      err(element, "missing one of event, cond, or target in <transition>")
   end
   -- cond() = condition evaluation (always return true if cond is missing)
   -- event  = nil, or a f(name) that returns true if the transition matches name
   local cond =  element.cond and chunk(element, "return "..element.cond) or alwaystrue
   local event = element.event and event_match(element) or nil
   -- By now store the target state ids. These will be replaced later (in fix_transition_targets())
   -- with the corresponding states (the reason for this deferred dereference is that
   -- the states may have not been added to idmap at this point yet).
   element._targetids = element.target and split(element.target) or {}
   element._target = {}
   local counters = executable_content()
   for _, child in ipairs(element) do
      validate(child, element, counters)
   end
   -- Find the source state of the transition.
   -- Note that this may be the parent or the granparent, because a <transition>
   -- may occur also as children of <history> or <initial>.
   -- Note also that although a <parallel> cannot directly contain a <transition>,
   -- it can indirectly by containing an <history> (and the same holds for <scxml>
   -- because of the 'initial' attribute which is equivalent to an <initial> element).
   local p = element._parent
   local tag = p.tag
   element._source = (tag=='state' or tag=='parallel' or tag=='scxml') and p or p._parent
   element._execute = function()
      for _, c in ipairs(element) do
         if not c._execute() then return false end
      end
      return true
   end
   local f = function(name)
      -- print("event", name, element.event, name and event(name), element.cond, cond())
         if not name then return not event and cond() -- matches the NULL event?
         else return cond() and event(name)
         end
      end
   element._match = function(name)
      local ok, res = pcall(f, name)
      if not ok then return error_execution(element, res) end
      return res
   end
end

-------------------------------------------------------------------------------
-- <IF> (executableblock), <ELSEIF>, <ELSE>
-------------------------------------------------------------------------------
-- The direct children of an <if> element (the 'master') are all executable
-- content elements, and are partitioned by any <elseif> and <else> direct
-- children. 0+ <elseif> followed by 0|1 <else> elements can occur as direct
-- children, delimiting the partitions borders:
--
-- <if>, cond1 (master)
--   |-...       1st partition, executed if if.cond=true
--   |-<elseif>, cond2
--   |-...       2nd partition, executed if cond2=true and cond1=false
--   |-...
--   |-<elseif>, condN
--   |-...       Nth partition, executed if condN=true and no previous cond is true
--   |-...       ...
--   |-<else>, cond=true always
--   `- ...      last partition, executed if no previous cond is true
-- 
-- Note that the master <if> may contain other <if> elements, but there is nothing
-- special about them and they are treated just like any other executable content.
--
-- <if>, <else>, and <elseif> meta attributes for internal use only:
-- _cond() = condition evaluation (for <else> elements this always returns true)
-- _first, _last = partition's borders
--
validate_func['if'] = function(element)
   local element = element
   check_attributes(element, 
      {}, -- optional
      { 'cond' }, -- mandatory
      {}, -- atleastoneof
      {}  -- onlyoneof
   )
   element._cond = chunk(element, "return "..element.cond)
   local counters = executable_content(); counters['elseif']=N; counters['else']=1
   local current = element -- current partitioning element
   local partitions = { current } -- ordered list of partitions
   current._first = 1
   local function new_partition(el, i) -- end current partition and begin new partition
      current._last = i-1 -- last element of the previous partition
      current = el
      current._first = i+1 -- first element of the new partition
      table_insert(partitions, current)
   end
   local last
   for i, child in ipairs(element) do
      validate(child, element, counters)
      if child.tag == 'elseif' then
         if counters['else']==0 then err(element, "<elseif> cannot occur after <else>") end
         new_partition(child, i)
      elseif child.tag == 'else' then
         new_partition(child, i)
      end
      last = i
   end
   current._last = last
   element._execute = (function()
      return function() 
         local _ENV = element._root._ENV
         for _, p in ipairs(partitions) do
            local ok, cond = pcall(p._cond)
            if not ok then return error_execution(element, cond) end
            if cond then
               for i = p._first, p._last do
                  if not element[i]._execute() then return false end
               end
               break
            end
         end
         return true
      end
   end)()
end

-------------------------------------------------------------------------------
validate_func['elseif'] = function(element)
   local element = element
   check_attributes(element, 
      {}, -- optional
      { 'cond' }, -- mandatory
      {}, -- atleastoneof
      {}  -- onlyoneof
   )
   element._cond = chunk(element, "return "..element.cond)
   no_children(element)
end

-------------------------------------------------------------------------------
validate_func['else'] = function(element)
   local element = element
   element._cond = alwaystrue
   no_children(element)
end

-------------------------------------------------------------------------------
-- <FOREACH> (executable)
-------------------------------------------------------------------------------
validate_func['foreach'] = function(element)
   local element = element
   check_attributes(element, 
      { 'index' }, -- optional
      { 'item', 'array' }, -- mandatory
      {}, -- atleastoneof
      {}  -- onlyoneof
   )
   local array = chunk(element, "return "..element.array) -- array must result in a table
   local set_index = element.index and chunk(element, element.index.."=select(2, ...)")
   local set_item = chunk(element, element.item.."=select(2, ...)")

   local ENV = element._root._ENV
   local counters = executable_content()
   for _, child in ipairs(element) do validate(child, element, counters) end

   local exec = function()
      local env = setmetatable({}, {__index=ENV, __newindex=ENV}) -- local environment
      -- do a shallow copy of array and iterate over it (see test525):
      local ok, _array = pcall(array)
      if not ok then return error_execution(element, _array) end
      if type(_array)~='table' then return error_execution(element, "'array' is not a table") end
      local a = {}
      for _k, _v in pairs(_array) do a[_k] = _v end
      for _k, _v in pairs(a) do
         --env[index], env[item] = _k, _v
         if set_index then set_index(nil, _k) end
         set_item(nil, _v)
         for _, c in ipairs(element) do
            if not c._execute(env) then return false end
         end
      end
      return true
   end

   element._execute = function() 
      local ok, errmsg = pcall(exec)
      if not ok then return error_execution(element, errmsg) end
      return errmsg -- true or false returned by exec
   end
end

-------------------------------------------------------------------------------
-- <LOG> (executable)
-------------------------------------------------------------------------------

validate_func['log'] = function(element)
   local element = element
   check_attributes(element, 
      { 'label', 'expr' }, -- optional
      {}, -- mandatory
      {}, -- atleastoneof
      {}  -- onlyoneof
   )
   local sessionid = element._root._sessionid
   local label = element.label
   local get_expr = chunk(element, "return "..(element.expr or 'nil'))
   local log = function() 
         if log_callback then log_callback(sessionid, label, get_expr()) end
      end
   element._execute = function()
      local ok, errmsg = pcall(log)
      if not ok then return error_execution(element, errmsg) end
      return true
   end
   no_children(element)
end

-------------------------------------------------------------------------------
-- <DATAMODEL> (executable), <data>
-------------------------------------------------------------------------------
validate_func['datamodel'] = function(element)
   local element = element
-- check_attributes(element, {}, {}, {}, {})
   local counters = { data=N }
   for _, child in ipairs(element) do
      validate(child, element, counters)
   end
   local bind = function() -- one shot only
      for _, data in ipairs(element) do
         local ok, errmsg = pcall(data._bind)
         if not ok then return error_execution(element, errmsg) end
      end
      return true
   end
   if element._root.binding == 'early' then -- all datamodels will be bound at init
      table_insert(element._root._datamodels, element)
   end
   element._execute = function()
      element._execute = alwaystrue -- next time do nothing
      return bind()
   end
end

-------------------------------------------------------------------------------
validate_func['data'] = function(element)
-- _bind() = assign value to variable (binding)
   local element = element
   check_attributes(element, 
      { 'src', 'expr', 'text' }, -- optional
      { 'id' }, -- mandatory
      {}, -- atleastoneof
      {{'src', 'expr', 'text'}}  -- onlyoneof
   )
   if not element.id then err(element, "missing id in <data>") end
   element.id = register_id(element)
   local set_val = chunk(element, element.id.."=select(2, ...)")
   local bind
   if element.expr then
      bind = chunk(element, element.id.." = "..element.expr)
   elseif element.src then
      if not data_callback then err(element, "data_callback() is not set") end
      bind = function() set_val(nil, data_callback(nil, element.src)) end
   elseif element.text then
      if not data_callback then err(element, "data_callback() is not set") end
      bind = function() set_val(nil, data_callback(element.text)) end
   else
      bind = chunk(element, element.id.." = nil") -- default
   end
   local invokeinfo = element._root._invokeinfo
   if invokeinfo and element._parent._parent.tag == 'scxml' then
      -- this is the top-level data element of an invoked 'scxml' session:
      -- we must use the value provided in invokeinfo.data, if any (see 6.4.3)
      element._bind = function()
         local val = invokeinfo.data[element.id]
         if val then -- use the value provided by the parent session
            set_val(nil, val)
         else -- use the value defined in the statechart
            bind()
         end
      end
   else
      element._bind = bind
   end
   no_children(element)
end

-------------------------------------------------------------------------------
-- <ASSIGN> (executable)
-------------------------------------------------------------------------------
-- _execute() retrieves the name of the variable (location) and the value, and
-- then assigns the value to the variable.

validate_func['assign'] = function(element)
   local element = element
   check_attributes(element, 
      { 'expr', 'text' }, -- optional
      { 'location' }, -- mandatory
      {{ 'expr', 'text' }}, -- atleastoneof
      {{ 'expr', 'text' }}  -- onlyoneof
   )
   local exec
   if is_readonly(element.location) then
      exec = function() error("cannot assign to location '"..element.location.."' (read only)") end
   elseif element.expr then
      exec = chunk(element, element.location.." = "..element.expr)
   else -- if element.text then
      exec = (function()
      local assign = chunk(element, element.location.."=select(2, ...)")
      if not data_callback then err(element, "data_callback() is not set") end
         return function() assign(nil, data_callback(element.text)) end
      end)()
   end
   element._execute = function()
      local ok, errmsg = pcall(exec)
      if not ok then return error_execution(element, errmsg) end
      return true
   end
   no_children(element)
end

-------------------------------------------------------------------------------
-- <SCRIPT> (executable)
-------------------------------------------------------------------------------

validate_func['script'] = function(element)
   local element = element
   check_attributes(element, 
      { 'src', 'text' }, -- optional
      {}, -- mandatory
      {{ 'src', 'text' }}, -- atleastoneof
      {{ 'src', 'text' }}  -- onlyoneof
   )
   local code = element.text or (script_callback and script_callback(element.src)) or nil
   local f = chunk(element, code)
   element._execute = function()
      local ok, errmsg = pcall(f)
      if not ok then return error_execution(element, errmsg) end
      return true
   end
   no_children(element)
end

-------------------------------------------------------------------------------
-- <RAISE> (executable)
-------------------------------------------------------------------------------
validate_func['raise'] = function(element)
   local element = element
   check_attributes(element, 
      {}, -- optional
      { 'event' }, -- mandatory
      {}, -- atleastoneof
      {}  -- onlyoneof
   )
   no_children(element)
   local name = element.event
   local scxml = element._root
   element._execute = function()
      local ok, errmsg = pcall(raise_event, scxml, {name=name, type='internal'})
      if not ok then return error_execution(element, errmsg) end
      return true
   end
end

-------------------------------------------------------------------------------
-- <SEND>, <CANCEL>
-------------------------------------------------------------------------------

validate_func['send'] = function(element)
   local element = element
   check_attributes(element, 
      { 'id', 'idlocation', 'event', 'eventexpr', 'target', 'targetexpr',
        'type', 'typeexpr', 'delay', 'delayexpr', 'namelist' }, -- optional
      {}, -- mandatory
      {}, -- atleastoneof
      -- onlyoneof:
      {{ 'id', 'idlocation'},
       {'event', 'eventexpr'},
       {'target', 'targetexpr'},
       {'type', 'typeexpr'},
       {'delay', 'delayexpr'}}
   )
   check_id_or_idlocation(element)
   -- we always generate a dynamic id, but we do not include it when delivering
   -- the message if not requested to:
   element._omit_sendid = not element.id and not element.idlocation

   local v = "nil"
   if element.event then v = "'"..element.event.."'"
   elseif element.eventexpr then v = element.eventexpr
   end
   local get_event = chunk(element, "return "..v) -- returns the event name (string or nil)

   local v = "nil"
   if element.target then v = "'"..element.target.."'"
   elseif element.targetexpr then v = element.targetexpr
   end
   local get_target = chunk(element, "return "..v) -- returns the target of the send (string or nil)

   local v = "'scxml'"
   if element.type then v = "'"..element.type.."'"
   elseif element.typeexpr then v = element.typeexpr
   end
   local get_sendtype = chunk(element, "return "..v) -- returns the send type (string or 'scxml')

   local get_delay -- returns the delay (seconds) or nil
   local v = element.delay and "'"..element.delay.."'" or element.delayexpr
   if v then
      local f = chunk(element, "return "..v)
      get_delay = function() return css2time(f()) end
   else
      get_delay = function() return nil end
   end

   local namelist = check_namelist(element)
   local params -- {<param> children} or nil
   local content -- child <content> or nil
   
   local counters = { param=N, content=1 }
   for _, child in ipairs(element) do
      validate(child, element, counters)
      local tag=child.tag
      if tag=='param' then
         if content then
            err(child, "<param> cannot occur with content in <send>")
         end
         params = params or {}
         params[#params+1] = child
      elseif tag=='content' then
         if params or namelist then
            err(child, "content cannot occur with namelist or <param> in <send>")
         end
         content = child
      end
   end

   -- Note: at any point in time a <send> element may have more than one sendid linked to it,
   -- because of the delay mechanism. That is, it may happen that the <send> element is
   -- executed again while a message from a previous execution of the same element is still
   -- waiting in the delay queue for its delivery time to come.

   local function get_data()
      if content then return { content = content._value() } end
      if not (namelist or params) then return nil end
      local data = namelist and namelist() or {}
      if params then
         for _, p in ipairs(params) do data[p.name] = p._value() end
      end
      return data
   end

   element._execute = function()
      local ok, sendtype = pcall(get_sendtype)
      if not ok then return error_execution(element, sendtype) end
      local ok, target = pcall(get_target)
      if not ok then return error_execution(element, target) end
      local ok, event = pcall(get_event)
      if not ok then return error_execution(element, event) end
      local ok, delay = pcall(get_delay)
      if not ok then return error_execution(element, delay) end

      if not ioprocessor_supported(sendtype) then
         return error_execution(element, "ioprocessor is not supported")
      end
      
      local ok, data = pcall(get_data)
      if not ok then return error_execution(element, data) end

      local sendinfo = { -- sendinfo
         element = element, -- for internal use only
         type = sendtype,
         target = target, 
         sendid = element.id or generate_dynamic_id(element),
         event = event,
         data = data,
      }
      
      -- Note: "The scxml processor must include all attributes and values
      -- provided by <param> or 'namelist' even if duplicates occur." (6.2.3)
      if delay and delay > 0 then
         element._root._sendinfo[sendinfo.sendid] = sendinfo -- store it for <cancel>
         delay_send(sendinfo, now()+delay)
         return true
      else
         return dispatch_send(sendinfo)
      end
   end
end

-------------------------------------------------------------------------------
validate_func['cancel'] = function(element)
   local element = element
   check_attributes(element, 
      { 'sendid', 'sendidexpr' }, -- optional
      {}, -- mandatory
      { {'sendid', 'sendidexpr'} }, -- atleastoneof
      { {'sendid', 'sendidexpr'} }  -- onlyoneof
   )
   local sendid = -- chunk that returns the sendid (string)
      chunk(element, "return "..(element.sendid and "'"..element.sendid.."'" or element.sendidexpr))
   local exec = function()
      -- Just mark as 'cancelled': actual cancellation will occur at the scheduled time.
      local sendinfo = element._root._sendinfo[sendid()]
      if sendinfo then sendinfo.cancelled = true end
   end
   element._execute = function()
      local ok, errmsg = pcall(exec)
      if not ok then return error_noaction(element, errmsg) end
      return true
   end
   no_children(element)
end

-------------------------------------------------------------------------------
-- <INVOKE>, <FINALIZE> (executable)
-------------------------------------------------------------------------------

validate_func['invoke'] = function(element)
-- _finalize(ev) = executes the <finalize> child if ev if from the invoked session
-- _check_done_event(ev): checks if ev is the done event for the invoked session
-- _cancel(): cancels the invoked session when the containing state is exited
-- _autoforward(ev): forwards the event ev to the invoked session
   local element = element
   check_attributes(element, 
      { 'id', 'idlocation', 'src', 'srcexpr', 'type', 'typeexpr',
      'namelist', 'autoforward' }, -- optional
      {}, -- mandatory
      {}, -- atleastoneof
      -- onlyoneof:
      {{'id', 'idlocation'},
       {'type', 'typeexpr'},
       {'src', 'srcexpr'}}
   )
   check_id_or_idlocation(element)

   local get_invoketype -- chunk that returns the invoke type (string or nil)
   if element.typeexpr then
      get_invoketype = chunk(element, "return "..element.typeexpr)
   else
      get_invoketype = function() return element.type or 'scxml' end
   end

   local autoforward = element.autoforward and chunk(element, "return "..element.autoforward)() or false

   local namelist = check_namelist(element)
   local get_src -- chunk that returns a string or nil
   local params -- {<param> children} or nil
   local content -- child <content> or nil
   local finalize -- child <finalize>, if any
   
   if element.src then
      get_src = function() return element.src end
   elseif element.srcexpr then
      get_src = chunk(element, "return "..element.srcexpr)
   else
      get_src = donothing
   end

   local counters = { param=N, content=1, finalize=1 }
   for _, child in ipairs(element) do
      validate(child, element, counters)
      local tag = child.tag
      if tag=='param' then
         if namelist then err(child, "<param> cannot occur with namelist in <invoke>") end
         params = params or {}
         params[#params+1] = child
      elseif tag=='content' then
         if element.src or element.srcexpr then
            err(child, "<content> cannot occur with src or srcexpr in <invoke>")
         end
         content = child
      elseif tag=='finalize' then
         finalize = child
      end
   end
   local parentid = element._root._sessionid
   local invokeinfo
   local done, doneevent

   local function get_data()
      if not (namelist or params or content) then return nil end
      local data = namelist and namelist() or {}
      if content then data.content = content._value() end
      if params then
         for _, p in ipairs(params) do data[p.name] = p._value() end
      end
      return data
   end

   element._execute = function()
      -- When the invoke is executed, if the evaluation of its arguments produces an error
      -- the processor must terminate the execution without further action (6.4.2)
      if not invoke_callback then
         return error_noaction(element, "invoke callback is not set")
      end
      local ok, src = pcall(get_src)
      if not ok then return error_noaction(element, src) end
      local ok, data = pcall(get_data)
      if not ok then return error_noaction(element, data) end
      local ok, invoketype = pcall(get_invoketype)
      if not ok then return error_noaction(element, invoketype) end

      invokeinfo = {
         parentid = parentid,
         type = invoketype,
         invokeid = element.id or generate_dynamic_id(element),
         autoforward = autoforward,
         src = src,
         data = data,
      }

      done, doneevent = false, 'done.invoke.'..invokeinfo.invokeid
      -- The invoke_callback is expected to invoke the requested service.
      -- The invoked service may either be a new local session or a remote service
      -- (a session in another application, or whatever). If it is a local session,
      -- the invoke callback is expected to return the sessionid assigned to it, so
      -- that the SCXML I/O processor can route automatically parent-to-child <send>s
      -- of the 'scxml' type, without the need of calling the send_callback.
      local ok, childid = pcall(invoke_callback, invokeinfo)
      if not ok then return error_noaction(element, childid) end
      if childid then
         element._root._childsession[invokeinfo.invokeid] = childid
      end
   end

   -- Note: at any moment in time there may be only one ongoing invocation caused by
   -- the same <invoke> element, because an invocation is executed only when the containing
   -- state is entered and cancelled when the state is exited.
   element._check_done_event = function(ev)
      -- This function is called when an external event is received by the session with
      -- the invocation being active. If the event is the 'done.invoke.id' event, it just
      -- marks the invocation as done, so that when the state containing the invocation
      -- is exited the cancel_callback is not called.
      if ev.name == doneevent then done = true end
   end
   local cancel = function()
      -- This function is called when the state contained the <invoke> is exited.
      -- If we know that the child session is already done, i.e. we received its
      -- 'done.invoke.id' event, then we take no further action is taken.
      -- Otherwise we assume that the child session is still ongoing and we cancel
      -- it (or attempt to) by calling the cancel_callback, if set.
      -- The callback is expected to cancel() the child, if it is a local session,
      -- or to signal the cancellation request to the remote provider, if not.
      if not invokeinfo then return end -- already cancelled?
      local childid = element._root._childsession[invokeinfo.invokeid]
      if childid then 
         element._root._childsession[invokeinfo.invokeid] = nil
      end
      if cancel_callback and not done then cancel_callback(invokeinfo, childid) end
      delete_dynamic_id(element, invokeinfo.invokeid)
      invokeinfo = nil
   end

   element._cancel = function()
      local ok, errmsg = pcall(cancel)
      if not ok then return error_noaction(element, errmsg.." (_cancel)") end
      return true
   end

   element._finalize = function()
      local ok, errmsg = pcall(cancel)
      if not ok then return error_noaction(element, errmsg" (_finalize)") end
      return true
   end

   element._finalize = finalize and function(ev)
      if ev.invokeid == invokeinfo.invokeid then
         local ok, errmsg = pcall(finalize._execute)
         if not ok then return error_execution(element, errmsg) end
      end
      return true
   end or alwaystrue

   local function forward(ev)
      -- send a copy of the event to the invoked session
      local sendinfo = {
            element = element, -- for internal use only
            type = 'scxml',
            target = '#_'..invokeinfo.invokeid,
            -- sendid = nil
            event = ev.name,
            data = ev.data,
         }
      dispatch_send(sendinfo)
   end
   element._autoforward = autoforward and function(ev)
      local ok, errmsg = pcall(forward, ev)
      if not ok then return error_execution(element, errmsg) end
      return true
   end or donothing
end

-------------------------------------------------------------------------------
validate_func['finalize'] = function(element)
   local element = element
   local counters = executable_content()
   counters.send, counters.raise = nil -- these are not allowed
   for _, child in ipairs(element) do validate(child, element, counters) end
   element._execute = function()
      for _, c in ipairs(element) do
         if not c._execute() then return false end
      end
      return true
   end
end

-------------------------------------------------------------------------------
-- <CONTENT>, <PARAM>, <DONEDATA>
-------------------------------------------------------------------------------

validate_func['content'] = function(element)
-- _value() = a chunk that returns the content (a string, or nil)
   local element = element
   check_attributes(element, 
      { 'expr', 'text' }, -- optional
      {}, -- mandatory
      {{'expr', 'text'}}, -- atleastoneof
      {{'expr', 'text'}}  -- onlyoneof
   )
   if element.expr then
      element._value = chunk(element, "return "..element.expr)
   elseif element.text then
      if not content_callback then err(element, "content_callback() is not set") end
      element._value = function() return content_callback(element.text) end
   end
   no_children(element)
end

-------------------------------------------------------------------------------
validate_func['param'] = function(element)
-- name = the param name
-- _value() = a chunk that returns the param value
   local element = element
   check_attributes(element, 
      { 'expr', 'location' }, -- optional
      { 'name' }, -- mandatory
      {{'expr', 'location'}}, -- atleastoneof
      {{'expr', 'location'}}  -- onlyoneof
   )
   if not element.name then err(element, "missing name in <param>") end
   element._value = chunk(element, "return ".. (element.expr or element.location))
   no_children(element)
end

-------------------------------------------------------------------------------
validate_func['donedata'] = function(element)
-- _value() = a function that returns the data in the format expected in events
   local element = element
   local content -- the child <content>, or nil
   local params -- the children <param>, or nil
   local counters = { content=1, param=N }
   for _, child in ipairs(element) do
      validate(child, element, counters)
      local tag = child.tag
      if tag=='param' then
         params = params or {}
         params[#params+1] = child
      elseif tag=='content' then
         content = child
      end
      if content and params then
         err(child, "cannot mix <content> and <param> in <donedata>")
      end
   end
   element._value = function()
      local data = {}
      if params then
         for _, p in ipairs(params) do data[p.name] = p._value() end
      elseif content then
         data.content = content._value()
      end
      return data
   end
end

-------------------------------------------------------------------------------
local function open(moonsc_, internal_)
   moonsc, internal = moonsc_, internal_
   now = moonsc.now
   moonsc.set_log_callback = function(func) log_callback=func end
   moonsc.set_script_callback = function(func) script_callback=func end
   moonsc.set_data_callback = function(func) data_callback=func end
   moonsc.set_content_callback = function(func) content_callback=func end
   moonsc.set_invoke_callback = function(func) invoke_callback=func end
   moonsc.set_cancel_callback = function(func) cancel_callback=func end
   internal.validate_statechart = validate_statechart
   internal.copy_statechart = copy_statechart
   internal.delete_dynamic_id = delete_dynamic_id
end

local function init(internal)
   err = internal.err
   valid_tag = internal.valid_tag
   isstate = internal.isstate
   isstate_or_history = internal.isstate_or_history
   raise_event = internal.raise_event
   error_execution = internal.error_execution
   error_noaction= internal.error_noaction
   dispatch_send = internal.dispatch_send
   delay_send = internal.delay_send
   ioprocessor_supported = internal.ioprocessor_supported
   is_readonly = internal.is_readonly
   css2time = internal.css2time
   split = internal.split
   event_match = internal.event_match
   chunk = internal.chunk
end

return { open = open, init = init }

