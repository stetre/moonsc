require("moonsc").import_tags()

-- Test that foreach goes over the array in the right order.
-- Since the array contains 1 2 3, we compare the current value with the
-- previous value, which is stored in var1. The current value should always
-- be larger. If it ever isn't, set Var4 to 0, indicating failure

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1", expr="0"}, -- contains the previous value
      _data{ id="var2" }, -- the item which will contain the current value
      _data{ id="var3", expr="{1, 2, 3}" },
      _data{ id="var4", expr="1" }, -- 1 if success, 0 if failure
   },
  
   _state{ id="s0",
      _onentry{
         _foreach{ item="var2", array="var3", 
            -- _log{ expr=[['var1='..var1..' var2='..var2..' cond='..tostring(var1<var2)]] },
            _if{ cond="var1 < var2",
               _assign{ location="var1", expr="var2" },
            _else{}, -- values are out of order, record failure
               _assign{ location="var4", expr="0" },
            },
         },
      },
      -- check that var1 has its original value
      _transition{ cond="var4==0", target="fail" },
      _transition{ target="pass" },
   },
   
   _final{id='pass'},
   _final{id='fail'},
}
