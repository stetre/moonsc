require("moonsc").import_tags()

-- We test that states are added to the active states list as they are
-- entered and before onentry handlers are executed.
-- When s0's onentry handler fires we should not be in s01. But when s01's
-- onentry handler fires, we should be in s01. Therefore event1 should not
-- fire, but event2 should. Either event1 or timeout also indicates failure  

return _scxml{ initial="s0",
   _state{ id="s0", initial="s01",
      _onentry{
         _send{ event="timeout", delay="1s" },
         _if{ cond="In('s01')", _raise{ event="event1" }}, 
      }, 
      _transition{ event="timeout", target="fail"  },
      _transition{ event="event1", target="fail" },
      _transition{ event="event2", target="pass" },
      _state{ id="s01",
         _onentry{
            _if{ cond="In('s01')", _raise{ event="event2" }}, 
         }, 
      }, 
   },
   _final{id='pass'},
   _final{id='fail'},
}

