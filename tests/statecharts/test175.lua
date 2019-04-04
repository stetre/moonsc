require("moonsc").import_tags()

-- Test that delayexpr uses the current value of var1, not its initial value
-- If it uses the initial value, event2 will be generated first, before event1.
-- If it uses the current value, event1 will be raised first.
-- Succeed if event1 occurs before event2, otherwise fail 

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1", expr="'0s'" },
   },
  
   _state{ id="s0",
      _onentry{
         _assign{ location="var1", expr="'1s'" },
         _send{ delayexpr="var1", event="event2" },
         _send{ delay=".5", event="event1" },
      },
      _transition{ event="event1", target="s1" },
      _transition{ event="event2", target="fail" },
   },

   _state{ id="s1",
      _transition{ event="event2", target="pass" },
      _transition{ event="*", target="fail" },
   },
   
   _final{id='pass'},
   _final{id='fail'},
}

