require("moonsc").import_tags()

-- We test that delayed <send> is not sent if the sending session terminates.
-- In this case, a subscript is invoked which sends the event childToParent
-- delayed by .5 seconds, and then terminates. The parent session, should not
-- receive childToParent. If it does, we fail. Otherwise the 1 sec timer
-- expires and we pass 

local SUB = [[
require("moonsc").import_tags()
return _scxml{ initial="sub0",
   _state{ id="sub0",
      _onentry{ _send{ event="childToParent", target="#_parent", delay=".5" }},
      -- exit before the delayed send can execute 
      _transition{  target="subFinal" },
   },
   _final{ id="subFinal" },
}]]

return _scxml{ initial="s0",
   _state{ id="s0",
      _onentry{ _send{ event="timeout", delay="1" }},
      _invoke{ type="scxml", _content{ text=SUB }},
      _transition{ event="childToParent", target="fail" },
      _transition{ event="timeout", target="pass" },
   },

   _final{id='pass'},
   _final{id='fail'},
}

