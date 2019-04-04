require("moonsc").import_tags()

-- Test that an error causes the foreach to stop execution.
-- The second piece of executable content should cause an error,
-- so var1 should be incremented only once

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1", expr="0" },
      _data{ id="var2" },
      _data{ id="var3", expr="{1,2,3}" },
      },
  
   _state{ id="s0",
      _onentry{
         _foreach{ item="var2", array="var3",
            _assign{ location="var1", expr="var1+1" },
            -- assign an illegal value to a non-existent var
            _assign{ location="var5", expr="'illegal expression '..(1>0)" },
         },
      },
      _transition{ cond="var1==1", target="pass" },
      _transition{ target="fail" },
   },
   
   _final{id='pass'},
   _final{id='fail'},
}

