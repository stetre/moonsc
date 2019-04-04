require("moonsc").import_tags()

-- we test that that we can't  cancel an event in another session. 
-- We invoke a child process. It notifies us when it has generated
-- a delayed event with sendid foo. We try to cancel foo. The child
-- process sends us event  event success if the event is not cancelled,
-- event fail otherwise. This doesn't test that there is absolutely no
-- way to cancel an event raised in another session, but the spec
-- doesn't define any way to refer to an event in another process  

    
-- SUB: When invoked, we raise a delayed event1 with sendid 'foo' and notify our parent.
-- Then we wait. If event1 occurs, the parent hasn't succeeded in canceling it and
-- we return pass. If event2 occurs it means event1 was canceled (because event2
-- is delayed longer than event1) and we return 'fail'.  
local SUB=[[
require("moonsc").import_tags()
return _scxml{ initial="sub0",
   _state{ id="sub0",
      _onentry{
         _send{ event="event1", id="foo", delay="1" },
         _send{ event="event2", delay="1.5" },
         _send{ target="#_parent", event="childToParent" },
      },
      _transition{ event="event1", target="subFinal",
         _send{ target="#_parent", event="pass" },
      },
      _transition{ event="*", target="subFinal",
         _send{ target="#_parent", event="fail" },
      },
   },
   _final{ id="subFinal" },
}]]

return _scxml{ initial="s0",
   _state{ id="s0", initial="s01",
      _onentry{_send{ event="timeout", delay="2" }},
      _invoke{ type="scxml", _content{ text=SUB }},
      _state{ id="s01",
         _transition{ event="childToParent", target="s02",
            _cancel{ sendid="foo" },
         },
      },
      _state{ id="s02",
         _transition{ event="pass", target="pass" },
         _transition{ event="fail", target="fail" },
         _transition{ event="timeout", target="fail" },
      },
   },

   _final{id='pass'},
   _final{id='fail'},
}

