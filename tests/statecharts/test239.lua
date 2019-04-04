require("moonsc").import_tags()


-- test that markup can be specified both by 'src' and by _content{  

-- identical to test239sub1.lua:
local SUB=[[
require("moonsc").import_tags()
return _scxml{  initial="final", _final{ id="final" }}
]]

return _scxml{ initial="s0",
   _state{ id="s0", initial="s01",
      _onentry{ _send{ event="timeout", delay="2s" }},
      _transition{ event="timeout", target="fail" },
      _state{ id="s01",
         _invoke{ type="scxml", src="file:statecharts/test239sub1.lua" },
         _transition{ event="done.invoke", target="s02" },
      },
      _state{ id="s02",
         _invoke{ type="scxml", _content{ text=SUB }},
         _transition{ event="done.invoke", target="pass" },
      },
   },
 
   _final{id='pass'},
   _final{id='fail'},
}

