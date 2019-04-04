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
local find_session -- imported function
-- shortcuts:
local string_match, string_gmatch = string.match, string.gmatch

-------------------------------------------------------------------------------
-- SCXML tags            
-------------------------------------------------------------------------------

local tags = {
   'scxml', 'state', 'parallel', 'transition', 'initial', 'final', 'onentry',
   'onexit', 'history', 'raise', 'if', 'elseif', 'else', 'foreach', 'log',
   'datamodel', 'data', 'assign', 'donedata', 'content', 'param', 'script',
   'send', 'cancel', 'invoke', 'finalize',
}

local valid_tag = -- predicate valid_tag(tag), true if tag is a valid SCXML tag
(function()
   local t = {}
   for _, v in ipairs(tags) do t[v]= true end
   return function(tag) return t[tag] or false end
end)()

local isstate = -- isstate(element) predicate
   (function() local t={state=true, parallel=true, final=true, scxml=true}
   return function(element) return t[element.tag] or false end end)()

local isstate_or_history = -- isstate_or_history (element) predicate
   (function() local t={state=true, parallel=true, final=true, history=true, scxml=true}
   return function(element) return t[element.tag] or false end end)()

local function import_tags(env) -- element constructors
   local env = env or _ENV
   for _, t in ipairs(tags) do
      env["_"..t] = function(c) -- env[t:upper()] = function(c)
         local el = c or {}
         el.tag = t
         return el
      end
   end
   -- env.TR = function(x) return { tag="log", label=tostring(x), expr="'@@TR'" } end -- debug only
end

-------------------------------------------------------------------------------
-- Element error function
-------------------------------------------------------------------------------

local function fmt(...) return string.format(...) end

local function path(element)
-- Returns a string with the element's containment path up to the containing state.
-- Can be used if the element and his ancestors have the _parent and tag attributes
-- in place.
   local function what(el) return el.tag..(el.id and "["..el.id.."]" or "") end
   local t = {}
   local el = element
   while el do
      t[#t+1]=what(el)
      if isstate(el) then break end
      el=el._parent
   end
   local t1 = {} for i=#t, 1, -1 do t1[#t1+1]=t[i] end
   return table.concat(t1, ".")
end

local function err(element, ...)
-- Formatted error(), with appended the containment path for the offending element.
   error("\nmoonsc: in element "..path(element)..":\n"..fmt(...), 2)
end

-------------------------------------------------------------------------------
-- Chunk compiler
-------------------------------------------------------------------------------

local Chunk = {} -- cached compiled chunks, indexed by the chunk's code

local function chunk(element, code)
-- Loads the passed code and returns the compiled chunk, which is a function
-- that accepts as optional first argument the _ENV where it must be executed
-- (if not passed, defaults to the dedicated _ENV for the element's session).
-- Additional arguments passed to the chunk can be accessed in the code with
-- select(n, ...), where n=2,3,...
-- The compiled chunk is cached for future use to avoid recompiling it if it is
-- reused (e.g. when more than one session is created with the same statechart).
-- Examples:
-- local f = chunk(element, "local a=select(2,...) print(a)")
-- f(_ENV, "Hello, World!")
-- f(nil, "Hello, World!") --> uses the default environment
-- local f = chunk(element, "return math.pi")
-- pi = f(_ENV)
   local f, errmsg
   if Chunk[code] then -- cached
      f = Chunk[code]
   else
      f, errmsg = load("local _ENV=select(1, ...) "..code) -- see PIL3/14.5
      if not f then err(element, errmsg) end
   end
   Chunk[code] = f
   local default_env = element._root._ENV
   return function(env, ...) return f(env or default_env, ...) end
end


-------------------------------------------------------------------------------
-- Miscellanea
-------------------------------------------------------------------------------
local function css2time(val)
-- Converts the passed value to a number denoting seconds.
-- val can be either a number (seconds), or a CSS2 time value, ie a string
-- composed of a number immediately followed by ms or s (eg '1000.1s', '12e3ms')
   local t = tonumber(val)
   if t then return t end -- a number denoting seconds
   t = string_match(val, '^([%d%.%-%+%e%E]+)ms$')
   if t and tonumber(t) then return tonumber(t)*1000 end
   t = string_match(val, '^([%d%.%-%+%e%E]+)s$')
   if t and tonumber(t) then return tonumber(t) end
   error("invalid css2 time value")
end

local function split(s, sep)
-- Splits the string s into a table of strings, assuming the separator sep.
   local sep = sep or ' '
   local t = {}
   local pattern = "([^"..sep.."]+)"
   for ss in string_gmatch(s, pattern) do t[#t+1] = ss end
   return t
end

local function valid_event_descriptor(d)
-- Returns true if d is a valid event descriptor (without any trailing '.' or '.*')
   for token in string_gmatch(d, "([^%.]*)") do
      if not string_match(token, "^[%w_]+$") then return false end
   end
   return true
end

local function alwaystrue() return true end

local function event_match(transition) -- transition = <transition> element
-- Checks if the event descriptors listed in transition.event are well-formed,
-- and returns a predicate f(name) whose value is true if name is matched by
-- any of the descriptors.
   local descr = split(transition.event)
   if #descr==0 then return nil end
   for i, ed in ipairs(descr) do
      if ed == '*' or ed == '.*' then -- this matches any name (and so does the transition)
         return alwaystrue
      end 
      local d = ed
      -- remove any trailing '.*' or '.'
      if d:sub(-2)=='.*' then d = d:sub(1, -3)
      elseif d:sub(-1)=='.' then d = d:sub(1,-2)
      end
      -- if ed is well-formed, d is now a sequence of dot-separated alphanumeric
      -- tokens, not ending with a dot
      if not valid_event_descriptor(d) then
         err(transition, "invalid event descriptor '%s'", ed)
      end
      -- Replace the descriptor with a descriptor-matches-name predicate
      -- (note that we add a trailing dot to both the descriptor and later to the
      -- name being tested, to avoid eg making the descriptor = 'aaa.bbb' match
      -- the name 'aaa.bbbccc', which would be wrong)
      descr[i] = (function(d)
         local pattern = '^'..d..'%.'
            return function(name) 
               --print("event_match", name, pattern, string_match(name, pattern))
               return string_match(name, pattern) and true or false
            end
         end)(d)
   end
   return function(name)
         local name = name..'.' -- because we made all descriptors end with a dot
         for _, f in ipairs(descr) do if f(name) then return true end end
         return false
      end
end

-------------------------------------------------------------------------------
-- Tostring utilities
-------------------------------------------------------------------------------

local tostring_attr = {}

local function tostring_scxml_(t, el, indent)
   local t = t or {}
   local indent = indent or ""
   local prefix0 = indent .. " └─"
   local prefix1 = indent .. " ├─"
   local indent0 = indent .. "   "
   local indent1 = indent .. " │ "
   t[#t+1] = "<"..el.tag
   t[#t+1]= el.id and " "..el.id..">" or ">"
   local f = tostring_attr[el.tag]
   if f then f(t, el, indent) end
   -- children
   t[#t+1] = '\n'
   for k, v in ipairs(el) do
      t[#t+1] = ((k==#el and prefix0 or prefix1))
      tostring_scxml_(t, v, k==#el and indent0 or indent1)
   end
end

local function cut(s, len)
   local len = len or 24
   return #s <= len and s or s:sub(1,len).." ..."
end

tostring_attr.scxml = function(t, el, indent)
   if el.name then t[#t+1]=" name='"..el.name.."'" end
   if el.version then t[#t+1]=" version="..el.version end
   if el.datamodel then t[#t+1]=" datamodel="..el.datamodel end
   if el.binding then t[#t+1]=" binding="..el.binding end
   if el.initial then t[#t+1]=" initial='"..el.initial.."'" end
end
tostring_attr.state = function(t, el, indent)
   if el.initial then t[#t+1]=" initial='"..el.initial.."'" end
end
tostring_attr.transition = function(t, el, indent)
   if el.event then t[#t+1]=" event='"..el.event.."'" end
   if el.cond then t[#t+1]=" cond=["..cut(el.cond).."]" end
   if el.target then t[#t+1]=" target='"..el.target.."'" end
   if el.type=='internal' then t[#t+1]=" (internal)" end
end
tostring_attr.history = function(t, el, indent)
   if el.type then t[#t+1]=" type="..el.type end
end
tostring_attr.raise = function(t, el, indent)
   if el.event then t[#t+1]=" event='"..el.event.."'" end
end
tostring_attr['if'] = function(t, el, indent)
   if el.cond then t[#t+1]=" cond=["..cut(el.cond).."]" end
end
tostring_attr['elseif'] = function(t, el, indent)
   if el.cond then t[#t+1]=" cond=["..cut(el.cond).."]" end
end
tostring_attr.foreach = function(t, el, indent)
   if el.index then t[#t+1]=" index='"..el.index.."'" end
   if el.item then t[#t+1]=" item='"..el.item.."'" end
   if el.array then t[#t+1]=" array=["..cut(el.array).."]" end
end
tostring_attr.log = function(t, el, indent)
   if el.label then t[#t+1]=" label='"..cut(el.label).."'" end
   if el.expr then t[#t+1]=" expr=["..cut(el.expr).."]" end
end
tostring_attr.data = function(t, el, indent)
   if el.src then t[#t+1]=" src='"..cut(el.src).."'" end
   if el.expr then t[#t+1]=" expr=["..cut(el.expr).."]" end
   if el.text then t[#t+1]=" text=["..cut(el.text).."]" end
end
tostring_attr.assign = function(t, el, indent)
   if el.location then t[#t+1]=" location='"..cut(el.location).."'" end
   if el.expr then t[#t+1]=" expr=["..cut(el.expr).."]" end
   if el.text then t[#t+1]=" text=["..cut(el.text).."]" end
end
tostring_attr.content = function(t, el, indent)
   if el.expr then t[#t+1]=" expr=["..cut(el.expr).."]" end
   if el.text then t[#t+1]=" text=["..cut(el.text).."]" end
end
tostring_attr.param = function(t, el, indent)
   if el.name then t[#t+1]=" name='"..cut(el.name).."'" end
   if el.location then t[#t+1]=" location='"..cut(el.location).."'" end
   if el.expr then t[#t+1]=" expr=["..cut(el.expr).."]" end
end
tostring_attr.script = function(t, el, indent)
   if el.src then t[#t+1]=" src='"..cut(el.src).."'" end
   if el.text then t[#t+1]=" text=["..cut(el.text).."]" end
end
tostring_attr.send = function(t, el, indent)
   if el.event then t[#t+1]=" event='"..el.event.."'" end
   if el.eventexpr then t[#t+1]=" eventexpr=["..cut(el.eventexpr).."]" end
   if el.target then t[#t+1]=" target='"..el.target.."'" end
   if el.targetexpr then t[#t+1]=" targetexpr=["..cut(el.targetexpr).."]" end
   if el.type then t[#t+1]=" type='"..el.type.."'" end
   if el.typeexpr then t[#t+1]=" typeexpr=["..cut(el.typeexpr).."]" end
   if el.idlocation then t[#t+1]=" idlocation=["..cut(el.idlocation).."]" end
   if el.delay then t[#t+1]=" delay='"..el.delay.."'" end
   if el.delayexpr then t[#t+1]=" delayexpr=["..cut(el.delayexpr).."]" end
   if el.namelist then t[#t+1]=" namelist='"..el.namelist.."'" end
end
tostring_attr.cancel = function(t, el, indent)
   if el.sendid then t[#t+1]=" sendid='"..el.sendid.."'" end
   if el.sendidexpr then t[#t+1]=" sendidexpr=["..cut(el.sendidexpr).."]" end
end
tostring_attr.invoke = function(t, el, indent)
   if el.type then t[#t+1]=" type='"..el.type.."'" end
   if el.typeexpr then t[#t+1]=" typeexpr=["..cut(el.typeexpr).."]" end
   if el.src then t[#t+1]=" src='"..el.src.."'" end
   if el.srcexpr then t[#t+1]=" srcexpr=["..cut(el.srcexpr).."]" end
   if el.idlocation then t[#t+1]=" idlocation=["..cut(el.idlocation).."]" end
   if el.autoforward then t[#t+1]=" autoforward="..el.autoforward end
   if el.namelist then t[#t+1]=" namelist='"..el.namelist.."'" end
end

local function tostring_scxml(scxml)
   local t = {}
   tostring_scxml_(t, scxml)
   return(table.concat(t))
end 

local function tostring_session(sessionid)
   local scxml = find_session(sessionid)
   return tostring_scxml(scxml)
end

-------------------------------------------------------------------------------
local function open(moonsc_, internal_)
   moonsc, internal = moonsc_, internal_
   moonsc.import_tags = import_tags 
   moonsc.tostring = tostring_session
   internal.err = err
   internal.path = path
   internal.isstate = isstate
   internal.isstate_or_history = isstate_or_history
   internal.valid_tag = valid_tag
   internal.css2time = css2time
   internal.split = split
   internal.event_match = event_match
   internal.chunk = chunk
end

local function init(internal)
   find_session = internal.find_session
end

return { open = open, init = init }

