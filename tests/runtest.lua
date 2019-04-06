#!/usr/bin/env lua
-- Executes either a single test or all tests (if called with no arguments)
-- A test is written as a Lua script returning a statechart that ends in
-- a top-level <final> state with id='pass', or in one with id='fail'.

local moonsc = require("moonsc")
local now, sleep = moonsc.now, moonsc.sleep
local verbose = false
local pass = false -- true if the last executed test succeeded

local function runtest(filename)
-- Executes a test, by creating a session with the statechart defined in the
-- given file.
   local f = assert(loadfile(filename))
   local statechart = f()
   print("*** Starting test '"..filename.."'")
   pass = false

   local sessionid = moonsc.generate_sessionid()
   moonsc.create(sessionid, statechart)
   moonsc.start(sessionid)

   local tnext = now()
   while tnext do
      sleep(tnext - now())
      tnext = moonsc.trigger()
   end

   print("*** TEST "..(pass and "PASSED" or "FAILED").." ("..filename..")")
   return pass
end

-------------------------------------------------------------------------------
-- Callbacks
-------------------------------------------------------------------------------

moonsc.set_trace_callback(function(sessionid, message)
   if verbose then print("["..sessionid.."] "..message) end
   -- To detect if the test succeeded, we just check from traces if it
   -- enters the 'pass' state (this is just an hack, and by no means the
   -- only way to do it):
   if message:sub(1,5)=='enter' and message:find('pass') then pass=true end
end)

moonsc.set_error_callback(function(...)
-- Shows errors on stdout when verbose.
   if not verbose then 
      moonsc.set_error_callback(nil)
      return
   end
   print("ERROR", ...)
   -- os.exit() -- uncomment this to exit at the first error
   -- Note that all callbacks are executed in protected mode (pcall)
   -- so raising a Lua error() here is not an option. If we don't want
   -- the application to continue execution after an error (eg because
   -- we are debugging it), we need to exit it using os.exit()).
end)

moonsc.set_log_callback(function(sessionid, label, expr)
-- Just shows the output from <log> elements on stdout.
   if not verbose then
      moonsc.set_log_callback(nil)
      return
   end
   print("["..sessionid.."] LOG "..
      (label and "(label:"..label..") " or "")..(expr and expr or ""))
end)

local function fetch_from_uri(uri)
-- If uri is a file name ("file:filename"), opens the file and returns
-- its content in a string. Any other kind of uri is not supported.
-- Used in callbacks that must fetch and return data. 
   local filename = string.match(uri, "^file:(.+)")
   if not filename then
      error("uri='"..uri.."' is not supported")
   end
   local f = assert(io.open(filename))
   local val = f:read('a')
   f:close()
   return val
end

moonsc.set_data_callback(function(text, src)
-- Called by <data> and <assign> elements to retrieve data specified
-- with the 'src' attribute or as inline content ('text' attribute).
   if text then return text end
   if src then return fetch_from_uri(src) end
end)

moonsc.set_script_callback(function(src)
-- Called by <script> elements to retrieve the script code when it is
-- specified with the 'src' attribute (a "file:filename" uri).
   if src then return fetch_from_uri(src) end
end)

moonsc.set_content_callback(function(text)
-- Called by <content> elements to retrieve content specified with the
-- 'text' attribute. Here we just return the attribute value (a string),
-- but a more complex application may interpret it (e.g. if it is markup)
-- and return something else.
   return text
end)

moonsc.set_send_callback(function(sendinfo)
-- This is called when a <send> element is executed and MoonSC is not able
-- to automatically route the event, either because the send 'type' is not
-- 'scxml', or because the 'target' attribute specifies a destination that
-- is not recognized as a SCXML session currently running in this application
-- (otherwise MoonSC would automatically send the event to the destination
-- without asking for help via this callback).
-- Here we are expected to recognize the destination, and deliver the event
-- or message to it, and return true on success, false if we recognize the
-- destination but we can not reach it, or raise a Lua error() in any other
-- case, e.g. we don't recognize the destination or don't support the 'type'.
-- (The difference between returning false or raising an error() is that in
--  the former case the sender will receive a 'error.communication' event,
--  while in the latter it will receive a 'error.execution'.)
--
   if sendinfo.type~='scxml' then
      error("unsupported <send> type") --> 'error.execution'
   end
   local target = sendinfo.target
   -- Is the target in the form '#_scxml_sessionid' ?
   local sessionid = string.match(target, '^#_scxml_([%w_]+)')
   if sessionid then -- the destination is the session identified by sessionid
      return false -- unreacheable destination -> 'error.comminication'
   end
   -- Is the target in the form '#_scxml_invokeid' ?
   local invokeid = string.match(target, '^#_([%w_]+)') -- '#_invokeid'
   if invokeid then -- destination is the child session whose invokeid is id
      return false -- unreacheable destination -> 'error.comminication'
   end
   -- ...
   error("unsupported <send> target") --> 'error.execution'
   -- Notice that in this callback we actually never route any message.
   -- This is because in our tests we only use the 'scxml' I/O processor and
   -- only communicate between local sessions, so this callback is executed only
   -- in case of errors. A 'real' application, however, could support other I/O
   -- processors or connect local sessions with remote entities by using this
   -- callback to route outgoing messages and the send() function to route
   -- incoming ones.
end)


moonsc.set_invoke_callback(function(invokeinfo)
-- This is called whenever a <invoke> element is executed. It is expected
-- to execute the requested service and return its sessionid, if the service
-- is a newly created local session, or nil if not.
-- (The returned sessionid, if any, will be used to automatically route any
-- event sent by the parent session to the child session).
-- On error (e.g. if there are invalid parameters in invokeinfo), this callback
-- may either ignore the request and do nothing or raise a Lua error() (this is
-- only for tracing purposes via the error callback, though, because no error
-- event is sent back to the invoking session, as per the SCXML Recommendation).
   if verbose then -- print the <invoke> parameters on stdout
      print("<invoke>")
      print("  type = "..(invokeinfo.type or "-"))
      print("  parentid = "..(invokeinfo.parentid or "-"))
      print("  invokeid = "..(invokeinfo.invokeid or "-"))
      print("  autoforward = "..(invokeinfo.autoforward and 'yes' or 'no'))
      print("  src = "..(invokeinfo.src or "-"))
      if invokeinfo.data then
         for k, v in pairs(invokeinfo.data) do print("  data."..k.." = "..tostring(v)) end
      end
   end

   if invokeinfo.type ~= 'scxml' then
      error("<invoke> type not supported")
   end
   -- Strictly speaking, the statechart of the invoked session should be defined
   -- by SCXML markup, either contained in the 'data.content' field, or in the uri
   -- specified by the 'src' field.
   -- Here we instead assume that (in both cases) it is defined by Lua code that,
   -- when executed, returns the statechart in its Lua-table equivalent form.
   -- This is a convenient way to execute Lua statecharts invoked by other Lua
   -- statecharts, but we are not obliged to use this method. We can devise any other
   -- method we like: what's essential is that the invoking session specifies a
   -- statechart (or other kind of service) in 'src' or 'data.content', and that this
   -- function knows how to interpret those fields so to know which statechart or
   -- service it must execute.
   local code
   if invokeinfo.src then code = fetch_from_uri(invokeinfo.src)
   else code = invokeinfo.data.content
   end
   if not code then error("missing 'src' or content in <invoke>") end
   local statechart = assert(load(code)(), "cannot load statechart")
   local childid = moonsc.generate_sessionid()
   moonsc.create(childid, statechart, false, invokeinfo)
   moonsc.start(childid)
   return childid
end)

moonsc.set_cancel_callback(function(invokeinfo, childid)
-- This is called when an invoked service is cancelled due to the parent
-- session exiting the state containing the <invoke> while the invocation
-- is ongoing. It is expected either to cancel() the child session (if the
-- service is a local session) or to signal the request for cancellation
-- to the remote service provider.
-- Note that after this, no events coming from the invoked service should
-- be sent to the invoking session. MoonSC takes care of ensuring this if
-- the invoked service is a local session, otherwise this task is up to
-- the application.
   if childid then moonsc.cancel(childid) end
end)

-------------------------------------------------------------------------------
-- Main
-------------------------------------------------------------------------------
-- Execute without arguments to run all tests, or pass a filename as argument
-- to run a single test in verbose mode, e.g.:
-- tests$ ./runtest.lua                            ;# run all tests
-- tests$ ./runtest.lua statecharts/test551.lua    ;# run test 551
--
-- (Note that it is assumed that this is executed in the tests/ directory.)

local filename = arg[1]
if filename then -- run a single test
   verbose = true
   runtest(filename)
else -- run all tests
   local list = require("testlist")
   local total, n, passed = #list, 0, 0
   local failed = {}
   for _, name in ipairs(list) do
      local filename = "statecharts/"..name..".lua"
      local f = io.open(filename)
      if f then
         n = n+1
         f:close()
         if runtest(filename) then
            passed = passed + 1
         else
            failed[#failed+1] = filename
         end
      end
   end
   print(string.format("Passed %d of %d (%.1f%%)", passed, n, passed/n*100))
   if #failed > 0 then
      print("Failed tests:")
      for _, filename in ipairs(failed) do print("- "..filename) end
   end
end

