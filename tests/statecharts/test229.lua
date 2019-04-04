require("moonsc").import_tags()

-- Test that autofoward works.
-- If the child  process receives back a copy of the childToParent event
-- that it sends to this doc, it sends eventReceived, signalling success.
-- (Note that this doc is not required to process that event explicitly.
-- It should be forwarded in any case.) Otherwise it eventually times out
-- and the done.invoke signals failure   

      
-- Substatechart: when invoked, send childToParent to parent.
-- If it is forwarded back to us, send eventReceived to signal success and
-- terminate.  Otherwise wait for timer to expire and terminate.
local SUB =[[
require("moonsc").import_tags()
return _scxml{ initial="sub0",
   _state{ id="sub0",
      _onentry{
         _send{ target="#_parent", event="childToParent" }, 
         _send{ event="timeout", delay="3s" }, 
      },
      _transition{ event="childToParent", target="subFinal",
         _send{ target="#_parent", event="eventReceived" },
      },
      _transition{ event="*", target="subFinal" },
   },
   _final{ id="subFinal" },
}]]


return _scxml{ initial="s0",
   _state{ id="s0",
      _onentry{ _send{ event="timeout", delay="3s" }},
      _invoke{ type="scxml", autoforward="true", _content{ text=SUB }},
      _transition{ event="childToParent" },
      _transition{ event="eventReceived", target="pass" }, 
      -- Note that also 'eventReceived' is autoforwarded (ie sent back to the child).
      -- This should cause an 'error.communication' (which we ignore) because the child
      -- exited just after having sent it to the parent so it is unreachable.
      _transition{ event="*", target="fail" },
   },

   _final{id='pass'},
   _final{id='fail'},
}

