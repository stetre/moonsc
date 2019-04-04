require("moonsc").import_tags()

-- Test that onentry handlers are executed in document order.
-- event1 should be raised before event2

return _scxml{
   _state{ id="s0",
      _onentry{ _raise{ event="event1" }},
      _onentry{ _raise{ event="event2" }},
      _transition{ event="event1", target="s1" },
      _transition{ event="*", target="fail" },
   },

   _state{ id="s1", 
      _transition{ event="event2", target="pass" },
      _transition{ event="*", target="fail" },
   },

   _final{id='pass'},
   _final{id='fail'},
}

