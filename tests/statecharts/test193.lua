require("moonsc").import_tags()

-- We test that omitting target and targetexpr of _send{ when using the
-- SCXML event i/o processor puts the event on the external queue.  

return _scxml{ initial="s0",
   _state{ id="s0",
      _onentry{
         _send{ event="internal" },
         -- this should put event1 in the external queue 
         _send{ event="event1", type="scxml" },
         _send{ event="timeout", delay="1s" },
      },
      _transition{ event="event1", target="fail" },
      _transition{ event="internal", target="s1" },
   },
 
   _state{ id="s1",
      _transition{ event="event1", target="pass" },
      _transition{ event="timeout", target="fail" },
   },

   _final{id='pass'},
   _final{id='fail'},
}

