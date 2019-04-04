require("moonsc").import_tags()

-- test that datamodel values can be specified by param.
-- the sub will return success if its var1 is set to 1, failure otherwise.  

local SUB = [[
require("moonsc").import_tags()
return _scxml{  initial="sub0",
   _datamodel{
      _data{ id="var1", expr="0" },
   },
   _state{ id="sub0",
      _transition{ cond="var1==1", target="subFinal",
         _send{ target="#_parent", event="success" },
      },
      _transition{  target="subFinal",
         _send{ target="#_parent", event="failure" },
      },
   },
   _final{ id="subFinal" },
}]]


return _scxml{ initial="s0",
   _state{ id="s0",
      _onentry{ _send{ event="timeout", delay="2s" }},
      _invoke{ type="scxml", _param{ name="var1", expr="1" }, _content{ text=SUB }},
      _transition{ event="success", target="pass" },
      _transition{ event="*", target="fail" },
   },
   _final{id='pass'},
   _final{id='fail'},
}

