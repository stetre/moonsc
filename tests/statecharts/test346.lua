require("moonsc").import_tags()

-- Test that any attempt to change the value of a system variable
-- causes error.execution to be raised.  
-- Event1..4 are there to catch the case where the error event is not raised.
-- In cases where it is, we have to dispose of eventn in the next state, hence
-- the targetless transitions (which simply throw away the event.) 

return _scxml{ initial="s0", name="machineName",
   _state{ id="s0",
      _onentry{
         _assign{ location="_sessionid", expr="'otherName'" },
         _raise{ event="event1" },
      },
      _transition{ event="error.execution", target="s1" },
      _transition{ event="*", target="fail" },
   },
   
   _state{ id="s1",
      _onentry{
         _assign{ location="_event", expr="'otherName'" },
         _raise{ event="event2" },
         },
      -- throw out event1 if it's still around 
      _transition{ event="event1" },
      _transition{ event="error.execution", target="s2" },
      -- event1 would trigger this transition if we didn't drop it. We want this
      -- transition to have a very general trigger to catch cases where the wrong
      -- error event was raised 
      _transition{ event="*", target="fail" },
   }, 
   
   _state{ id="s2",
      _onentry{
         _assign{ location="_ioprocessors", expr="'otherName'" },
         _raise{ event="event3" },
      },
      _transition{ event="event2" },
      _transition{ event="error.execution", target="s3" },
      _transition{ event="*", target="fail" },
   }, 
   
   _state{ id="s3",
      _onentry{
         _assign{ location="_name", expr="'otherName'" },
         _raise{ event="event4" },
      },
      _transition{ event="event3" },
      _transition{ event="error.execution", target="pass" },
      _transition{ event="*", target="fail" },
   }, 

   _final{id='pass'},
   _final{id='fail'},
}

