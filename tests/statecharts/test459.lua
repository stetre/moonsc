require("moonsc").import_tags()

-- test that foreach goes over the array in the right order. 
-- since the array contains 1 2 3, we compare the current value with
-- the previous value, which is stored in var1. The current value should
-- always be larger. If it ever isn't, set Var5 to false, indicating failure.
-- Also check that the final value of the index is the length of the array. 

return _scxml{ initial="s0", datamodel="lua",
   _datamodel{
      _data{ id="Var1", expr="0" }, -- contains the previous value 
      _data{ id="Var2" }, -- the item which will contain the current value
      _data{ id="Var3" }, -- the index 
      _data{ id="Var4", expr="{1,2,3}" },
      _data{ id="Var5", expr="true" }, -- success or failure 
   },
  
   _state{ id="s0",
      _onentry{
         _foreach{ item="Var2", array="Var4", index="Var3",
            _if{ cond="Var1 < Var2",
               _assign{ location="Var1", expr="Var2" },
            _else{ }, -- values are out of order, record failure 
               _assign{ location="Var5", expr="false" },
            },
         },
      },
      -- check that var1 has its original value  
      _transition{ cond="Var1==0 or Var3 ~= #Var4", target="fail" },
      _transition{ cond="not Var5", target="fail" },
      _transition{ target="pass" },
   },

   _final{id='pass'},
   _final{id='fail'},
}

