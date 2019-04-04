require("moonsc").import_tags()

-- we test that #_invokeid works as  a target of _send{.
-- A child  script is invoked and sends us childToParent once
-- its running.  Then we send it the event parentToChild using
-- its invokeid as the target.
-- If it receives this event, it sends sends the event eventReceived
-- to its parent session (ths session). If we get this event, we pass,
-- otherwise the child script eventually times out sends invoke.done
-- and we fail. We also set a timeout in this process to make sure the
-- test doesn't hang  

-- Sub: let the parent session know we're running by sending
-- childToParent, then wait for parentToChild. If we get it,
-- send eventReceived.  If we don't we eventually time out 
local SUB = [[
require("moonsc").import_tags()
return _scxml{ initial="sub0",
   _state{ id="sub0",
      _onentry{
         _send{ event="childToParent", target="#_parent" },
         _send{ event="timeout", delay="3s" },
      },
      _transition{ event="parentToChild", target="subFinal",
         _send{ target="#_parent", event="eventReceived" },
      },
      _transition{ event="timeout", target="subFinal" },
   },
   _final{ id="subFinal" },
}]]

return _scxml{ initial="s0",
   _state{ id="s0", initial="s01",
      _onentry{ _send{ event="timeout", delay="5s" }},
      _invoke{ type="scxml", id="invokedChild", _content{ text=SUB }},
      _transition{ event="timeout", target="fail" }, 
      _transition{ event="done.invoke", target="fail" },
      _state{ id="s01",
         _transition{ event="childToParent", target="s02",
            _send{ target="#_invokedChild", event="parentToChild" },
         },
      },
      _state{ id="s02",
         _transition{ event="eventReceived", target="pass" },
      },
   },

   _final{id='pass'},
   _final{id='fail'},
}

