require("moonsc").import_tags()

-- test that _foreach{ does a shallow copy, so that modifying
-- the array does not change the iteration behavior. 


return _scxml{ datamodel="lua",
   _datamodel{
      _data{ id="Var1", expr="{1,2,3}" },
      _data{ id="Var2", expr="0" },  -- counts the number of iterations 
   },
     
   _state{ id="s0",
      _onentry{
         _foreach{ item="Var3", array="Var1",
            -- _script{ text="Var1[#Var1 +1] = 4" }, -- alt.
            _assign{ location="Var1[#Var1+1]", expr="4" },
            _assign{ location="Var2", expr="Var2 + 1" },
            _log{ expr="'Var1 = '..table.concat(Var1, ', ') .. ' / Var2 = '..Var2" },
         },
      },
   
   _transition{ cond="Var2==3", target="pass" },
   _transition{ target="fail" },
},

   _final{id='pass'},
   _final{id='fail'},
}

