require("moonsc").import_tags()

-- Test late binding.
-- var2 won't get bound until s1 is entered, so it shouldn't have
-- a value in s0 and accessing it should cause an error. It should
-- get bound before the onentry code in s1 so it should be possible
-- access it there and assign its value to var1 

return _scxml{ initial="s0", binding="late",
   _datamodel{
      _data{ id="var1" },
   },  
     
   _state{ id="s0",
      _transition{ cond="var2==nil", target="s1" },
      _transition{ target="fail" },
   }, 
   
   _state{ id="s1",
      _datamodel{
         _data{ id="var2", expr="1" },
      }, 
      _onentry{ _assign{ location="var1", expr="var2" }}, 
      _transition{ cond="var1==var2", target="pass" },
      _transition{ target="fail" },
   }, 
   
   _final{id='pass'},
   _final{id='fail'},
}

