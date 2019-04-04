require("moonsc").import_tags()

-- we test that the processor raises error.communication if it cannot
-- dispatch the event. (To create an undispatchable event, we choose a
-- non-existent session as target). If it raises the error event, we
-- succeed.  Otherwise we eventually timeout and fail.  

return _scxml{ initial="s0",
   _state{ id="s0",
      _onentry{
      _send{ target="#_scxml_unknownsessionid", event="event2" }, -- should cause an error 
      -- this will get added to the external event queue after the error has been raised:
      _send{ event="timeout" },
   },
 
   -- once we've entered the state, we should check for internal events first    
      _transition{ event="error.communication", target="pass" },
      _transition{ event="*", target="fail" },
   },
 
   _final{id='pass'},
   _final{id='fail'},
}

