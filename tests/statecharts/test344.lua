require("moonsc").import_tags()

-- Test that a cond expression that cannot be evaluated as a
-- boolean cond expression evaluates to false and causes
-- error.execution to be raised.
-- In some languages, any valid expression/object can be converted
-- to a boolean, so conf:nonBoolean will have to be mapped onto
-- something that produces a syntax error or something similarly invalid 

return _scxml{ initial="s0",
   _state{ id="s0",
      _transition{ cond="nonBoolean()", target="fail" }, -- not defined
      _transition{ target="s1" },
   }, 
  
   _state{ id="s1",
      _onentry{ _raise{ event="foo" }},
      _transition{ event="error.execution", target="pass" },
      _transition{ event="*", target="fail" },
   }, 
    
   _final{id='pass'},
   _final{id='fail'},
}

