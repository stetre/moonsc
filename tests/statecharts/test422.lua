require("moonsc").import_tags()

-- Test that at the end of a macrostep, the processor executes all
-- invokes in states that have been entered and not exited during the step.
-- (The invokes are supposed to be executed in document order, but we can't
-- test that since each invocation is separate and they may take different
-- amounts to time to start up.)  In this case, there are three invoke
-- statements, in states s1, s11 and s12.  Each invoked process returns an
-- event named after its parent state.
-- The invokes in s1 and s12 should execute, but not the one in s11. So we
-- should receive invokeS1, invokeS12, but not invokeS12. Furthermore, when
-- the timeout fires, var1 should equal 2.


-- Inline scripts for sub-statecharts
local SUB1 = [[
require("moonsc").import_tags()
-- when invoked, send 'foo' to parent, then terminate.   
return _scxml{ initial="sub0",
   _state{ id="sub0",
      _onentry{ _send{ target="#_parent", event="invokeS1" }},
      _transition{ target="subFinal0" },
   },
   _final{ id="subFinal0" },
}]]

local SUB2 =  [[
require("moonsc").import_tags()
-- when invoked, send 'foo' to parent, then terminate.   
return _scxml{ initial="sub1",
   _state{ id="sub1",
      _onentry{ _send{ target="#_parent", event="invokeS11" }},
      _transition{ target="subFinal1" },
   },
   _final{ id="subFinal1" },
}]]

local SUB3 = [[
require("moonsc").import_tags()
-- when invoked, send 'foo' to parent, then terminate.   
return _scxml{ initial="sub2",
   _state{ id="sub2",
      _onentry{ _send{ target="#_parent", event="invokeS12" }},
      _transition{ target="subFinal2" },
   },
   _final{ id="subFinal2" },
}]]

return _scxml{ initial="s1",
   _datamodel{
      _data{ id="var1", expr="0" },
   },
   
   _state{ id="s1", initial="s11",
      _onentry{ _send{ event="timeout", delay="2" }},
      _transition{ event="invokeS1 invokeS12",
        _assign{ location="var1", expr="var1+1" },
      },
      _transition{ event="invokeS11", target="fail" },
      _transition{ event="timeout", cond="var1==2", target="pass" },
      _transition{ event="timeout", target="fail" },
      _invoke{ _content{ text=SUB1 },
      },

      _state{ id="s11",
         _invoke{ _content{ text=SUB2 }},
         _transition{ target="s12" },
      },

      _state{ id="s12",
         _invoke{ _content{ text=SUB3 }},
      },
   },
 
   _final{id='pass'},
   _final{id='fail'},
}

