require("moonsc").import_tags()

-- Test that foreach causes a new variable to be declared if 'item'
-- doesn't already exist.  Also test that it will use an existing var
-- if it does exist.

return _scxml{ initial="s0", 
   _datamodel {
      _data{ id="var1" },
      _data{ id="var2" },
      _data{ id="var3", expr="{1, 2, 3}" },
   },
  
   _state{ id="s0",
      _onentry{ -- first use declared variables
         _foreach{ item="var1", index="var2", array="var3", _raise{ event="foo" }}
      },
      _transition{ event="error", target="fail" },
      _transition{ event="*", target="s1" },
   },
   
   _state{ id="s1",
      _onentry{ -- now use undeclared variables
         _foreach{ item="var4", index="var5", array="var3", _raise{ event="bar" }}
      },
      _transition{ event="error", target="fail" },
      _transition{ event="*", target="s2" },
   },

   _state{ id="s2",
      -- check that var5 is bound
      _transition{ cond="var5~=nil", target="pass" },
      _transition{ target="fail" },
   },

   _final{id='pass'},
   _final{id='fail'},
}

