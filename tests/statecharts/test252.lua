require("moonsc").import_tags()

-- Test that we don't process any events received from the invoked
-- process once it is cancelled. child process tries to send us
-- childToParent in an onexit handler. If we get it, we fail. @@ who should stop it, and where?
-- timeout indicates success.   

local SUB = [[
require("moonsc").import_tags()
return _scxml{ initial="sub0",
   _state{ id="sub0",
      _onentry{ _send{ event="timeout", delay=".5" }},
      _transition{ event="timeout", target="subFinal" },
      _onexit{ _send{ target="#_parent", event="childToParent" } },
   },
   _final{ id="subFinal" },
}]]

return _scxml{ initial="s0",
   _state{ id="s0", initial="s01",
      _onentry{ _send{ event="timeout", delay="1" }},
      _transition{ event="timeout", target="pass" },
      _transition{ event="childToParent", target="fail" },
      _transition{ event="done.invoke", target="fail" },
      _state{ id="s01",
         _onentry{ _send{ event="foo" }},
         _invoke{ type="scxml", _content{ text=SUB }},
         -- this transition will cause the invocation to be cancelled 
         _transition{ event="foo", target="s02" },
      },
      _state{ id="s02" },
   },
 
   _final{id='pass'},
   _final{id='fail'},
}

