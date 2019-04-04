require("moonsc").import_tags()

-- Test that executable content in the <initial> transition executes after the
-- onentry handler on the state and before the onentry handler of the child states.
-- Event1, event2, and event3 should occur in that order. 

return _scxml{ initial="s0",
   _state{ id="s0", initial="s01",
      _onentry{ _send{ event="timeout", delay="1s" }}, 
      _transition{ event="timeout", target="fail"  },
      _transition{ event="event1", target="fail" },
      _transition{ event="event2", target="pass" },
      _state{ id="s01",
         _onentry{ _raise{ event="event1" }}, 
         _initial{ _transition{ target="s011", _raise{ event="event2" }}, 
      }, 
         _state{ id="s011",
            _onentry{ _raise{ event="event3" }}, 
            _transition{ target="s02" },
         }, 
      }, 
      _state{ id="s02",
         _transition{ event="event1", target="s03" },
         _transition{ event="*", target="fail" },
      }, 
      _state{ id="s03",
         _transition{ event="event2", target="s04" },
         _transition{ event="*", target="fail" },
      }, 
      _state{ id="s04",
         _transition{ event="event3", target="pass" },
         _transition{ event="*", target="fail" },
      }, 
   }, -- end s0 
 
   _final{id='pass'},
   _final{id='fail'},
}

