require("moonsc").import_tags()

-- Test that invokeid is set correctly in events received from
-- an invoked process.  timeout event catches the case where the
-- invoke doesn't work correctly 

local SUB = [[
return _scxml{ initial="sub0", name="machineName",     
   _final{ id="sub0",
      _onentry{ _send{ target="#_parent", event="event1" }},
   },
}]]

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1" },
      _data{ id="var2" },
   },
  
   _state{ id="s0",
      _onentry{ _send{ event="timeout", delay="2s" }},
      _invoke{ location="var1", type="scxml", _content{ text=SUB }},
      _transition{ event="event1", target="s1",
         _assign{ location="var2", expr="_invokeid" },
      },
      _transition{ event="event0", target="fail" },
   },

   _state{ id="s1",
      _transition{ cond="var1==var2", target="pass" },
      _transition{ target="fail" },
   },
  
   _final{id='pass'},
   _final{id='fail'},
}

