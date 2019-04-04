require("moonsc").import_tags()

-- Test that typeexpr uses the current value of var1, not its initial value
-- If it uses the initial value, it will generate an error.  If it uses the
-- current value, event1 will be raised  

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1", expr="'invalidsendtype'" },
   },
  
   _state{ id="s0",
      _onentry{
         _assign{ location="var1", expr="'scxml'" },
         --_assign{ location="var1", expr="'http://www.w3.org/TR/scxml/#SCXMLEventProcessor'" },
         _send{ typeexpr="var1", event="event1" },
      },
      _transition{ event="event1", target="pass" },
      _transition{ event="*", target="fail" },
   },
   
   _final{id='pass'},
   _final{id='fail'},
}

