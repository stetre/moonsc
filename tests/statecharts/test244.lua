require("moonsc").import_tags()

-- Test that datamodel values can be specified by  namelist.
-- invoked child will return success ifits var1 is set to 1,
-- failure otherwise.
-- This test will fail schema validation due to multiple occurrences
-- of var1, but should run correctly. 

local SUB = [[
require("moonsc").import_tags()
return _scxml{ initial="sub0",
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
   _datamodel{
      _data{ id="var1", expr="1" },
   },
   _state{ id="s0",
      _onentry{ _send{ event="timeout", delay="2s" }},
      _invoke{ type="scxml", namelist="var1", _content{ text=SUB }},
      _transition{ event="success", target="pass" },
      _transition{ event="*", target="fail" },
   },
   _final{id='pass'},
   _final{id='fail'},
}

