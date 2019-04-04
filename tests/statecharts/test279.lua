require("moonsc").import_tags()

-- Testing that in case of early binding variables are assigned
-- values at init time, before the state containing them is visited  

return _scxml{ initial="s0",    
   _state{ id="s0",
      _transition{ cond="var1==1", target="pass" },
      _transition{ target="fail" },
   }, 
   _state{ id="s1",
      _datamodel{ _data{ id="var1", expr="1" }}, 
   }, 
   
   _final{id='pass'},
   _final{id='fail'},
}

