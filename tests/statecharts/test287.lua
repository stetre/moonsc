require("moonsc").import_tags()

-- A simple test that a legal value may be assigned to a valid data model location 

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1", expr="0" },
   },   
     
   _state{ id="s0",
      _onentry{ _assign{ location="var1", expr="1" }}, 
      _transition{ cond="var1==1", target="pass" },
      _transition{ target="fail" },
   }, 

   _final{id='pass'},
   _final{id='fail'},
}


