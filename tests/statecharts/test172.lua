require("moonsc").import_tags()

-- Test that eventexpr uses the current value of var1, not its initial value  

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1", expr="'event1'" },
   },
  
   _state{ id="s0",
      _onentry{
         _assign{ location="var1", expr="'event2'" },
         _send{ eventexpr="var1" },
      },
      _transition{ event="event2", target="pass" },
      _transition{ event="*", target="fail" },
   },
   
   _final{id='pass'},
   _final{id='fail'},
}

