require("moonsc").import_tags()

-- Test that datamodel values can be specified both by 'namelist' and by _param{.
-- invoked child will return success if its Var1 is set to 1, failure otherwise.
-- This test will fail schema validation because of the multiple occurences of Var1,
-- but should run correctly. 

local SUB1 = [[
require("moonsc").import_tags()
return _scxml{ initial="sub01",
   _datamodel{ _data{ id="var1", expr="0" }},
   _state{ id="sub01",
      _transition{ cond="var1==1", target="subFinal1", -- var1 is overridden by invoke data
         _send{ target="#_parent", event="success" },
      },
      _transition{  target="subFinal1",
         _send{ target="#_parent", event="failure" },
      },
   },
   _final{ id="subFinal1" },
}]]

local SUB2 = [[
require("moonsc").import_tags()
return _scxml{ initial="sub02",
   _datamodel{ _data{ id="var1", expr="0" }},
   _state{ id="sub02",
      _transition{ cond="var1==1", target="subFinal2", -- var1 is overridden by invoke data
         _send{ target="#_parent", event="success" },
      },
      _transition{  target="subFinal2",
         _send{ target="#_parent", event="failure" },
      },
   },
   _final{ id="subFinal2" },
}]]

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1", expr="1" },
   },
     
   _state{ id="s0", initial="s01",
      _onentry{ _send{ event="timeout", delay="2s" }},
      _transition{ event="timeout", target="fail" },
      _state{ id="s01",
         _invoke{ type="scxml", namelist="var1", _content{ text=SUB1 }},
         _transition{ event="success", target="s02" },
         _transition{ event="failure", target="fail" },
      },
      _state{ id="s02",
         _invoke{ type="scxml", _content{ text=SUB2 }, _param{ name="var1", expr="1" }},
         _transition{ event="success", target="pass" },
         _transition{ event="failure", target="fail" },
      },
   },
 
   _final{id='pass'},
   _final{id='fail'},
}

