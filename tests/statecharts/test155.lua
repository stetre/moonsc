require("moonsc").import_tags()

-- Test that foreach executes the executable content once for each item
-- in the list '(1,2,3)'. The executable content sums the items into var1
-- so it should be 6 at the end

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1", expr="0" },
      _data{ id="var2" },
      _data{ id="var3", expr="{1,2,3}" },
   },
  
   _state{ id="s0",
      _onentry{
         _foreach{ item="var2", array="var3",
            _assign{ location="var1", expr="var1+var2" },
         }
      },
      _transition{ cond="var1==6", target="pass" },
      _transition{ target="fail" },
   },

   _final{id='pass'},
   _final{id='fail'},
}

