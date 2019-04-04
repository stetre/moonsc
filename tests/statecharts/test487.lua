require("moonsc").import_tags()

-- Test illegal assignment.  error.execution should be raised.  

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1" },
   }, 
     
   _state{ id="s0",
      _onentry{
      -- _assign{ location="var1", expr="" }, @@ this is illegal, but catched at initialization
         _assign{ location="var1", expr="''..true" }, -- this is illegal, and catched at evaluation
         _raise{ event="event" },
      }, 
      _transition{ event="error.execution", target="pass" },
      _transition{ event="*", target="fail" },
   },
 
   _final{id='pass'},
   _final{id='fail'},
}

