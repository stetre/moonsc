require("moonsc").import_tags()

-- Test that a script is evaluated at load time. 
-- The script should assign the value 1 to var1.  Hence, if script is
-- evaluated at download time, Var1 has a value in the initial state s0.

return _scxml{ initial="s0",
   _script{ text=[[var1=1]] },
   _state{ id="s0",
      _transition{ cond="var1==1", target="pass" },
      _transition{ target="fail" },
   }, 
   _final{id='pass'},
   _final{id='fail'},
}

