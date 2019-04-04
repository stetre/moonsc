require("moonsc").import_tags()

-- Test that assignment with an illegal expr raises an error 

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1", expr="1" },
   }, 

   _state{ id="s0",
      _onentry{
         _assign{ location="var1", expr="illegal()" },
         _raise{ event="foo" },
      }, 
      _transition{ event="error.execution", target="pass" },
      _transition{ event=".*", target="fail" },
   }, 
    
   _final{id='pass'},
   _final{id='fail'},
}

