require("moonsc").import_tags()

-- Test that states are exited in exit order (children before parents with
-- reverse doc order used to break ties before the executable content in the
-- transitions. event1, event2, event3, event4 should be raised in that 
-- order when s01p is exited

return _scxml{ initial="s0",
   _state{ id="s0", initial="s01p",
      _parallel{ id="s01p",
         -- this should be the third event raised
         _onexit{ _raise{ event="event3" }},
         -- this should be the fourth event raised
         _transition{ target="s02", _raise{ event="event4" }}, 
         _state{ id="s01p1",
            -- this should be the second event raised
            _onexit{ _raise{ event="event2" }}, 
         },
         _state{ id="s01p2",
            -- this should be the first event raised
            _onexit{ _raise{ event="event1" }}, 
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
         _transition{ event="event3", target="s05" },
         _transition{ event="*", target="fail" },
      }, 
      _state{ id="s05",
         _transition{ event="event4", target="pass" },
         _transition{ event="*", target="fail" },
      }, 
   }, 

   _final{id='pass'},
   _final{id='fail'},
}

