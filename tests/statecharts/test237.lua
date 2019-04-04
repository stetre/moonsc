require("moonsc").import_tags()

-- Test that cancelling works. 
-- invoked child sleeps for two seconds, then terminates.
-- We sleep for 1 sec in s0, then move to s1.  This should cause
-- the invocation to get cancelled. If we receive done.invoke, the
-- invocation wasn't cancelled, and we fail. If we receive no events
-- by the time timeout2 fires, success   

-- Subchart: when invoked, sleep for 2 secs then terminate.
-- Parent will try to cancel this session 
local SUB = [[
require("moonsc").import_tags()
return _scxml{ initial="sub0",
   _state{ id="sub0",
      _onentry{ _send{ event="timeout", delay="2" }},
         _transition{ event="timeout", target="subFinal" },
   },  
   _final{ id="subFinal" },
}]]

return _scxml{ initial="s0",
   _state{ id="s0",
      _onentry{ _send{ event="timeout1", delay="1" }},
      _invoke{ type="scxml", _content{ text=SUB }},
      _transition{ event="timeout1", target="s1" },    
   },

   _state{ id="s1",
      _onentry{ _send{ event="timeout2", delay="1.5" }},
      -- here we should NOT get done.invoke 
      _transition{ event="done.invoke", target="fail" },
      _transition{ event="*", target="pass" },
   },
 
   _final{id='pass'},
   _final{id='fail'},
}

