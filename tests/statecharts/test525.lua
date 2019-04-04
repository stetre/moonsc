require("moonsc").import_tags()

-- Test that <foreach> does a shallow copy, so that modifying the
-- array does not change the iteration behavior.

return _scxml{
   _datamodel{
      _data{ id="var1", expr="{1,2,3}" },
      _data{ id="var2", expr="0" },  -- counts the number of iterations
   },
     
   _state{ id="s0",
      _onentry{
         _foreach{ item="var3", array="var1",
            _assign{ location="var1[#var1+1]", expr="1" },
            _assign{ location="var2", expr="var2+1" },
         },
      },
      _transition{ cond="var2==3", target="pass" },
      _transition{ target="fail" },
   },

   _final{id='pass'},
   _final{id='fail'},
}

