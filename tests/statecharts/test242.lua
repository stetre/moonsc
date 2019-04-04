require("moonsc").import_tags()

-- test that markup specified  by 'src' and by <content> is treated
-- the same way. That means that either we get done.invoke in both cases
-- or in neither case (in which case we timeout) 

local SUB = [[
require("moonsc").import_tags()
return _scxml{ initial="final",
   _final{ id="final" }
}]]

return _scxml{ initial="s0",
   _state{ id="s0",
      _onentry{ _send{ event="timeout1", delay="1s" }},
      _transition{ event="timeout", target="fail" },
      _invoke{ type="scxml", src="file:statecharts/test242sub1.lua" },
      _transition{ event="done.invoke", target="s02" },
      _transition{ event="timeout1", target="s03" },
   },

   _state{ id="s02",
      _onentry{ _send{ event="timeout2", delay="1s" }},
      _invoke{ type="scxml", _content{ text=SUB }}, -- identical to test242sub1.lua.  
      _transition{ event="done.invoke", target="pass" },
      _transition{ event="timeout2", target="fail" },
   },
 
   _state{ id="s03",
      _onentry{ _send{ event="timeout3", delay="1s" }},
      _invoke{ type="scxml", _content{ text=SUB }}, -- identical to test242sub1.lua.  
      _transition{ event="timeout3", target="pass" },
      _transition{ event="done.invoke", target="fail" },
   },

   _final{id='pass'},
   _final{id='fail'},
}

