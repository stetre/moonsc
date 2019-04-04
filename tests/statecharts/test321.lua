require("moonsc").import_tags()

-- test that _sessionid is bound on startup 

return _scxml{ initial="s0", name="machineName",
   _datamodel{
      _data{ id="var1", expr="_sessionid" },
   }, 
     
   _state{ id="s0",
      _transition{ cond="var1~=nil", target="pass"  },
      _transition{ cond="true", target="fail" },
   }, 
   
   _final{id='pass'},
   _final{id='fail'},
}

