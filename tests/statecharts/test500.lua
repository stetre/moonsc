require("moonsc").import_tags()

-- test that location field is found inside entry for SCXML Event I/O processor 

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1", expr="_ioprocessors.scxml.location" },
   },
  
   _state{ id="s0",
      _transition{ cond="var1~=nil", target="pass" },
      _transition{ target="fail" },
   },
  
   _final{id='pass'},
   _final{id='fail'},
}

