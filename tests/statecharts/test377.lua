require("moonsc").import_tags()

-- Test that onexit handlers are executed in document order.
-- event1 should be raised before event2

return _scxml{

   _state{ id="s0",
      _onexit{ _raise{event="event1"}},
      _onexit{ _raise{event="event2"}},
      _transition{ target="s1" },
   },
 
   _state{ id="s1",
      _transition{ event="event1",  target="s2" },
      _transition{ event="*", target="fail" },
   },

   _state{ id="s2",
      _transition{ event="event2", target="pass" },
      _transition{ event="*", target="fail" },
   },
 
   _final{id='pass'},
   _final{id='fail'},
}

