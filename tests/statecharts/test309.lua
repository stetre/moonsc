require("moonsc").import_tags()

-- Test that an expression that cannot be interpreted
-- as a boolean is treated as false


return _scxml{ initial="s0",
   _state{ id="s0", 
      _transition{ cond="", target="fail" }, -- @@ false and nil are falsy, everything else is truthy
      _transition{ target="pass" },
      }, 
    
   _final{id='pass'},
   _final{id='fail'},
}

