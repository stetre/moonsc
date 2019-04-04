require("moonsc").import_tags()

-- We test that the automatically generated id is unique,
-- we call invoke twice and compare the ids.

local SUB = [[
require("moonsc").import_tags()
return _scxml{ initial="subFinal2", _final{ id="subFinal2" }}
]]

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1" },
      _data{ id="var2" },
   },
     
   _state{ id="s0",
      _onentry{ _send{ event="timeout", delay="1s" }},
      _invoke{ type="scxml", idlocation="var1", _content{ text=SUB }},
      _invoke{ type="scxml", idlocation="var2", _content{ text=SUB }},
      _transition{ event="*", target="s1" },
   },

   _state{ id="s1",
      _transition{ cond="var1==var2", target="fail" },
      _transition{ target="pass", _log{ expr="'invokeids: '..var1..', '..var2" }}
   },

   _final{id='pass'},
   _final{id='fail'},
}

