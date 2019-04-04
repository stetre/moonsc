require("moonsc").import_tags()

-- we test that #_internal as a target of <send> puts the event on the
-- internal queue.  If it does, event1 will be processed before event2,
-- because event1 is added to the internal queue while event2 is added
-- to the external queue (event though event2 is generated first)  

return _scxml{ initial="s0",
   _state{ id="s0",
      _onentry{
         _send{ event="event2" }, -- goes to the external queue 
         _send{ event="event1", target="#_internal" }, -- to the internal queue 
      },
       -- once we've entered the state, we should check for internal events first    
      _transition{ event="event1", target="pass" },
      _transition{ event="event2", target="fail" },
   },

   _final{id='pass'},
   _final{id='fail'},
}

