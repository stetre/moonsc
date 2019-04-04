require("moonsc").import_tags()

-- We test that _send{ respects the delay specification.
-- If it does, event1 arrives before event2 and we pass.
-- Otherwise we fail  

return _scxml{ initial="s0",
   _state{ id="s0",
      _onentry{
         _send{ event="event2", delay="1" },
         _send{ event="event1" },
      }, 
      _transition{ event="event1", target="s1" },
      _transition{ event="*", target="fail" },
   }, 
   _state{ id="s1",
      _transition{ event="event2", target="pass" },
      _transition{ event="*", target="fail" },
   }, 
   _final{id='pass'},
   _final{id='fail'},
}

