require("moonsc").import_tags()

-- We test that specifying an illegal target for <send> causes
-- the event error.execution to be raised.  If it does, we succeed.
-- Otherwise we eventually timeout and fail.  

return _scxml{ initial="s0",
   _state{ id="s0",
      _onentry{
   _send{ target="", event="event2" }, -- should cause an error 
   -- this will get added to the external event queue after the error has been raised 
   _send{ event="timeout" },
},
 
 -- once we've entered the state, we should check for internal events first    
  _transition{ event="error.execution", target="pass" },
  _transition{ event="*", target="fail" },
 },

   _final{id='pass'},
   _final{id='fail'},
}

