require("moonsc").import_tags()

-- Test that the executable content in the transitions is executed in
-- document order after the states are exited.
-- event1, event2, event3, event4 should be raised in that order when
-- the state machine is entered

return _scxml{ initial="s0",
   _state{ id="s0", initial="s01p",
      _onentry{ _send{ event="timeout", delay="1s" }}, 
      _transition{ event="timeout", target="fail" },

      _parallel{ id="s01p",
         _transition{ event="event1", target="s02" },
         _state{ id="s01p1", initial="s01p11",
            _state{ id="s01p11",
               -- this should be the second event raised
               _onexit{ _raise{ event="event2" }}, 
               -- this should be the third event raised
               _transition{ target="s01p12", _raise{ event="event3" }}, 
            }, 
            _state{ id="s01p12" },
         },
         _state{ id="s01p2", initial="s01p21",
            _state{ id="s01p21",
               -- this should be the first event raised
               _onexit{ _raise{ event="event1" }}, 
               -- this should be the fourth event raised
               _transition{ target="s01p22", _raise{ event="event4" }}, 
            }, 
            _state{ id="s01p22" },
         },
      }, 
  
      _state{ id="s02",
         _transition{ event="event2", target="s03" },
         _transition{ event="*", target="fail" },
      }, 
    
      _state{ id="s03",
         _transition{ event="event3", target="s04" },
         _transition{ event="*", target="fail" },
      }, 

    
      _state{ id="s04",
         _transition{ event="event4", target="pass" },
         _transition{ event="*", target="fail" },
      }, 
   }, -- end s01

   _final{id='pass'},
   _final{id='fail'},
}

