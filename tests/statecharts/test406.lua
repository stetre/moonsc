require("moonsc").import_tags()

--  Test that states are entered in entry order (parents before children
--  with document order used to break ties) after the executable content
--  in the transition is executed.
--  event1, event2, event3, event4 should be raised in that order when the
--  transition in s01 is taken

return _scxml{ initial="s0",
   _state{ id="s0", initial="s01",
      _onentry{ _send{ event="timeout", delay="1s" }}, 
      _transition{ event="timeout", target="fail" },
      _state{ id="s01",
         -- this should be the first event raised 
         _transition{ target="s0p2", _raise{ event="event1" }}, 
      }, 
      _parallel{ id="s0p2",
         _transition{ event="event1", target="s03" },
         _state{ id="s01p21",
            _onentry{ _raise{ event="event3" }}, -- third event 
         }, 
         _state{ id="s01p22",
            _onentry{ _raise{ event="event4" }}, -- the fourth event 
         }, 
         _onentry{ _raise{  event="event2" }}, -- this should be the second event raised 
      }, 
      _state{ id="s03",
         _transition{ event="event2", target="s04" },
         _transition{ event="*", target="fail" },
      }, 
      _state{ id="s04",
         _transition{ event="event3", target="s05" },
         _transition{ event="*", target="fail" },
      }, 
      _state{ id="s05",
         _transition{ event="event4", target="pass" },
         _transition{ event="*", target="fail" },
      }, 
   },  -- end s0 
   _final{id='pass'},
   _final{id='fail'},
}

