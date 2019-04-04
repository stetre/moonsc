require("moonsc").import_tags()

-- Test that an illegal array or item value causes error.execution and
-- results in executable content not being executed.

return _scxml{ initial="s0",
   _datamodel{ 
      _data{ id="var1", expr="0" },
      _data{ id="var2" },
      _data{ id="var3" },
      _data{ id="var4", expr="'illegal array'" },
      _data{ id="var5", expr="{1, 2, 3 }" },
   },
   _state{ id="s0",
      _onentry{ -- invalid array, legal item
         _foreach{ item="var2", index="var3", array="var4",
            _assign{ location="var1", expr="var1+1" },
         },
        _raise{ event="foo" },
      },
      _transition{ event="error.execution", target="s1" },
      _transition{ event="*", target="fail" },
   },
   
   _state{ id="s1",
      _onentry{ -- illegal item, legal array
      --[[ @@ Note: we skip the test for the illegal item because MoonSC catches
      --          such an error at element initialization, i.e. before starting
      --          the session.
         _foreach{ item="", index="var3", array="var5" , -- illegal item
            _assign{ location="var1", expr="var1+1" },
         },
      --]]
         _raise{ event="error.execution.xxx" }, --@@ emulates the above error
         _raise{ event="bar" },
      },
      _transition{ event="error.execution", target="s2" },
      _transition{ event="bar", target="fail" },
   },

   _state{ id="s2",
      -- check that var1 has its original value (so executable content never got executed
      _transition{ cond="var1==0", target="pass" },
      _transition{ target="fail" },
   },
   
   _final{id='pass'},
   _final{id='fail'},
}
