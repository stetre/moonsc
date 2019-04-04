require("moonsc").import_tags()

-- Test that the scxml event I/O processor works by sending events
-- back and forth between an invoked child and its parent process 

local SUB = [[
require("moonsc").import_tags()
return _scxml{ initial="sub0", name="machineName",  
   _state{ id="sub0",
      _onentry{ _send{ type="scxml", target="#_parent", event="childToParent" }},
      _transition{ event="parentToChild", target="subFinal" },
   },
   _final{ id="subFinal" },
}]]

return _scxml{ initial="s0",
   _state{ id="s0", initial="s01",
      _invoke{  id="child", type="scxml", _content{ text=SUB }},
      _onentry{ _send{ delay="20s", event="timeout" }},
      _transition{ event="timeout", target="fail" },
        
      _state{ id="s01",
         _transition{ event="childToParent", target="s02" },
      },
    
      _state{ id="s02",
         _onentry{ _send{ type="scxml", target="#_child", event="parentToChild" }},
         _transition{ event="done.invoke", target="pass" },
         _transition{ event="error", target="fail" },
      },
   },
  
   _final{id='pass'},
   _final{id='fail'},
}

