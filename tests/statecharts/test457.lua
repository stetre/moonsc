require("moonsc").import_tags()

-- test that the legal iterable array are tables
-- and that the legal values for the 'item' attribute on foreach
-- are legal lua variable names

return _scxml{ initial="s0", datamodel="lua",
   _datamodel{
      _data{ id="Var1", expr="0" },
      _data{ id="Var2" },
      _data{ id="Var3" },
      _data{ id="Var4", expr="7" },
      _data{ id="Var5", expr="{1,2,3}" },
      _data{ id="Var6" },
   },
  
   _state{ id="s0",
      _onentry{
         -- invalid array, legal item 
         _foreach{ item="Var2", index="Var3", array="Var4",
            _assign{ location="Var1", expr="Var1 + 1" },
         },
         _raise{ event="foo" },
     },
      _transition{ event="error.execution", target="s1" },
      _transition{ event="*", target="fail" }, 
   },
   
   _state{ id="s1",
      _onentry{
         -- illegal item, legal array 
         -- _foreach{ item="goto", index="Var3", array="Var5",  -- @@ this is detected at init
         _foreach{ item="illegal.item", index="Var3", array="Var5",
            _assign{ location="Var1", expr="Var1 + 1" },
         },
         _raise{ event="bar" },
      },
      _transition{ event="error.execution", target="s2" },
      _transition{ event="bar", target="fail" }, 
   },

   _state{ id="s2",
      -- check that var1 has its original value (so executable content never got executed 
      _transition{ cond="Var1==0", target="s3" },
      _transition{ target="fail" },
   },

   -- finally check that a legal array works properly 
   _state{ id="s3",
      _onentry{
         _assign{ location="Var6", expr="0" },
         _foreach{ item="Var2", array="Var5",
            _assign{ location="Var6", expr="Var6 + Var2" },
         },
      },
      _transition{ cond="Var6==6", target="pass" },
      _transition{ target="fail" },
   },  
   
   _final{id='pass'},
   _final{id='fail'},
}

