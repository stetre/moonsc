require("moonsc").import_tags()

-- test that non-existent datamodel values are not set.
-- var2 is not defined in invoked child's datamodel.
-- It will will return success if its var2 remains unbound, failure otherwise.  

local SUB = [[
require("moonsc").import_tags()
return _scxml{ initial="sub0",
   _state{ id="sub0",
      _transition{ cond="var2~=nil", target="subFinal",
         _send{ target="#_parent", event="failure" },
      },
      _transition{  target="subFinal",
         _send{ target="#_parent", event="success" },
      },
   },  
   _final{ id="subFinal" },
}]]

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var2", expr="3" },
   },
   _state{ id="s0",
      _onentry{ _send{ event="timeout", delay="2s" }},
      _invoke{ type="scxml", namelist="var2", _content{ text=SUB }},
      _transition{ event="success", target="pass" },
      _transition{ event="*", target="fail" },
   },
 
   _final{id='pass'},
   _final{id='fail'},
}

