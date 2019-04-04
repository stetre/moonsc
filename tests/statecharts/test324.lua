require("moonsc").import_tags()

-- Test that _name stays bound till the session ends.
-- This means that it cannot be assigned to 

return _scxml{ initial="s0", name="machineName",
   _state{ id="s0",
      _transition{ cond="_name=='machineName'", target="s1" },
      _transition{ target="fail" },
   },
   
   _state{ id="s1",
      _onentry{ _assign{ location="_name", expr="'otherName'" }},
      _transition{ cond="_name=='machineName'", target="pass" },
      _transition{ target="fail" },
   }, 
   
   _final{id='pass'},
   _final{id='fail'},
}

