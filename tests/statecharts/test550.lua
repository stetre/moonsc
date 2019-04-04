require("moonsc").import_tags()

-- Test that expr can be used to assign a value to a var.
-- This test uses early binding 

return _scxml{ initial="s0", binding="early",
   _state{ id="s0",
      _transition{ cond="var1==2", target="pass" },
      _transition{ target="fail" },
    }, 
   
   _state{ id="s1",
      _datamodel{ _data{ id="var1", expr="2" }}, 
   }, 

   _final{id='pass'},
   _final{id='fail'},
}

