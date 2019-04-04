require("moonsc").import_tags()

-- We test that #_parent works as  a target of  _send{.
-- a subscript is invoked and sends the event childToParent to its
-- parent session (ths session) using #_parent as the target.
-- If we get this event, we pass, otherwise we fail. The timer insures
-- that some event is generated and that the test does not hang. 

-- Sub: send an event to the parent session using #_parent as the target 
local SUB = [[
require("moonsc").import_tags()
return _scxml{ initial="sub0",
   _state{ id="sub0",
      _onentry{ _send{ event="childToParent", target="#_parent" }},
         _transition{  target="subFinal" },
      },
   _final{ id="subFinal" },
}]]

return _scxml{ initial="s0",
   _state{ id="s0",
      _onentry{ _send{ event="timeout", delay="5s" }},
      _invoke{ type="scxml", _content{ text=SUB }},
      _transition{ event="childToParent", target="pass" },
      _transition{ event="*", target="fail" },
   },

   _final{id='pass'},
   _final{id='fail'},
}

