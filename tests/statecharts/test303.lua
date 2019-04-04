require("moonsc").import_tags()

-- To test that scripts are run as part of executable content,
-- we check that it changes the value of a var at the right point.
-- This test is valid only for datamodels that support scripting

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1", expr="0" },
   },
     
   _state{ id="s0",
      _onentry{
         _assign{ location="var1", expr="2" },
         _script{ text=[[var1 = 1]] },
      }, 
      _transition{ cond="var1==1", target="pass" },
      _transition{ target="fail" },
   }, 
   
   _final{id='pass'},
   _final{id='fail'},
}

