require("moonsc").import_tags()

-- The child process will return success if its var1 is set to 1,
-- failure otherwise. For this test we try passing in var1 by param
-- and by namelist and check that we either get two successes or two
-- failures.  This test will fail schema validation due to multiple
-- declarations of var1, but should  run correctly.  

local SUB1 = [[
require("moonsc").import_tags()
return _scxml{ initial="sub01",
   _datamodel{ _data{ id="var1", expr="0" }},
   _state{ id="sub01",
      _transition{ cond="var1==1", target="subFinal1",
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
      _transition{ cond="var1==1", target="subFinal2",
         _send{ target="#_parent", event="success" },
      },
      _transition{  target="subFinal2",
         _send{ target="#_parent", event="failure" },
      },
   },
   _final{ id="subFinal2" },
}]]

local SUB3 = [[
require("moonsc").import_tags()
return _scxml{ initial="sub03",
   _datamodel{ _data{ id="var1", expr="0" }},
   _state{ id="sub03",
      _transition{ cond="var1==1", target="subFinal3",
         _send{ target="#_parent", event="success" },
      },
      _transition{  target="subFinal3",
         _send{ target="#_parent", event="failure" },
      },
   },
   _final{ id="subFinal3" },
}]]

return _scxml{ initial="s0",
   _datamodel{ _data{ id="var1", expr="1" }},
   _state{ id="s0", initial="s01",
      _onentry{ _send{ event="timeout", delay="2s" }},
      _transition{ event="timeout", target="fail" },

      _state{ id="s01",
         _invoke{ type="scxml", namelist="var1", _content{ text=SUB1 }},
         _transition{ event="success", target="s02" },
         _transition{ event="failure", target="s03" },
      },

      _state{ id="s02",
         _invoke{ type="scxml", _param{ name="var1", expr="1" }, _content{ text=SUB2 }},
         _transition{ event="success", target="pass" },
         _transition{ event="failure", target="fail" },
      },
  
      _state{ id="s03",
         _invoke{ type="scxml", _param{ name="var1", expr="1" }, _content{ text=SUB3 }},
         _transition{ event="failure", target="pass" },
      _transition{ event="success", target="fail" },
      },
   },
 
   _final{id='pass'},
   _final{id='fail'},
}

