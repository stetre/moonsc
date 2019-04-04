require("moonsc").import_tags()

-- Test that _ioprocessors is bound at startup. 

return _scxml{ initial="s0", name="machineName",
   _datamodel{
     _data{ id="var1", expr="_ioprocessors" },
   }, 

   _state{ id="s0",
      _transition{ cond="var1~=nil", target="pass" },
      _transition{ target="fail" },
   }, 
   
   _final{id='pass'},
   _final{id='fail'},
}

