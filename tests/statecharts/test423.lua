require("moonsc").import_tags()

-- Test that we keep pulling external events off the queue till
-- we find one that matches a transition.

return _scxml{ initial="s0",
   _state{ id="s0",
      _onentry{
         _send{ event="externalEvent1" },
         _send{ event="externalEvent2", delay="1" },
         _raise{ event="internalEvent" },
      },
      -- in this state we should process only internalEvent
      _transition{ event="internalEvent", target="s1" },
      _transition{ event="*", target="fail" },
   },
   
   _state{ id="s1",
      -- in this state we ignore externalEvent1 and wait for externalEvent2
      _transition{ event="externalEvent2", target="pass" },
      _transition{ event="internalEvent", target="fail" },
   },
   
   _final{id='pass'},
   _final{id='fail'},
}


