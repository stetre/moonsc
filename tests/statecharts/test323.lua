require("moonsc").import_tags()

-- Test that _name is bound on startup

return _scxml{ initial="s0", name="machineName",
   _datamodel{
      _data{ id="var1", expr="_name" },
   }, 
     
   _state{ id="s0",
      _transition{ cond="var1~=nil", target="pass"  },
      _transition{ cond="true", target="fail" },
   }, 

   _final{id='pass'},
   _final{id='fail'},
}

