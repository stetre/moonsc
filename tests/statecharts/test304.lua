require("moonsc").import_tags()

-- Test that a variable declared by a script can be accessed like
-- any other part of the data model

return _scxml{ initial="s0",
   _script{ text=[[var1 = 1]] },
   _state{ id="s0",
      _transition{ cond="var1==1", target="pass" },
      _transition{ target="fail" },
   }, 
   
   _final{id='pass'},
   _final{id='fail'},
}

