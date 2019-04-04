require("moonsc").import_tags()

-- we test that #_scxml_sessionid as a target of <send> puts the event
-- on the external queue.  If it does, event1 will be processed before
-- event2, because event1 is added to the internal queue while event2 is
-- added to the external queue (event though event2 is generated first).
-- we have to make sure that event2 is actually delivered. The delayed
-- <send> makes sure another event is generated (so the test doesn't hang) 


return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1", expr="'#_scxml_'" },
      _data{ id="var2", expr="_sessionid" },
   },
  
   _state{ id="s0",
      _onentry{
         -- goes to the external queue:
         _send{ event="event2", targetexpr="var1..var2" },
         -- to the internal queue:
         _raise{ event="event1" },
         -- this should get added to the external queue after event2:
         _send{ event="timeout" },
      },
      -- once we've entered the state, we should check for internal events first    
      _transition{ event="event1", target="s1" },
      _transition{ event="*", target="fail" },
   },
 
   -- now check that we get event2 and not a timeout 
   _state{ id="s1",
      _transition{ event="event2", target="pass" },
      _transition{ event="*", target="fail" },
   },

   _final{id='pass'},
   _final{id='fail'},
}


