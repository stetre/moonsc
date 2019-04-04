require("moonsc").import_tags()

-- test that done.invoke.id event is the last event we receive.
-- the invoked process sends childToParent in the exit handler
-- of its final state.  We should get it before the done.invoke,
-- and we should get no events after the done.invoke.
-- Hence timeout indicates success   

local SUB = [[
require("moonsc").import_tags()
return _scxml{ initial="subFinal",
   _final{ id="subFinal",
      _onexit{ _send{ target="#_parent", event="childToParent" }},
   },
}]]

return _scxml{ initial="s0",
   _state{ id="s0",
      _onentry{ _send{ event="timeout", delay="2" }},
      _invoke{ type="scxml", _content{ text=SUB }},
      _transition{ event="childToParent", target="s1" },    
      _transition{ event="done.invoke", target="fail" },
   },

   _state{ id="s1",
      -- here we should get done.invoke 
      _transition{ event="done.invoke", target="s2" },
      _transition{ event="*", target="fail" },
   },
  
   _state{ id="s2",
      _transition{ event="timeout", target="pass" },
      _transition{ event="*", target="fail" },
   },  
 
   _final{id='pass'},
   _final{id='fail'},
}

