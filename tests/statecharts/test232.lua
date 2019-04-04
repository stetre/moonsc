require("moonsc").import_tags()

-- test that a parent process can receive multiple events from a child process

local SUB = [[
require("moonsc").import_tags()
return _scxml{ initial="subFinal",
   _final{ id="subFinal",
      _onentry{
         _send{ target="#_parent", event="childToParent1" }, 
         _send{ target="#_parent", event="childToParent2" },
      },
   },
}]]

return _scxml{ initial="s0",
   _state{ id="s0", initial="s01",
      _onentry{ _send{ event="timeout", delay="3s" }},
      _invoke{ type="scxml",  _content{ text=SUB }},
      _transition{ event="timeout", target="fail" },
      _state{ id="s01",
        _transition{ event="childToParent1", target="s02" },
      },
      _state{ id="s02",
         _transition{ event="childToParent2", target="s03" },
      },
      _state{ id="s03",
         _transition{ event="done.invoke", target="pass" },
      },  
   },
   _final{id='pass'},
   _final{id='fail'},
}

