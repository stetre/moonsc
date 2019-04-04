require("moonsc").import_tags()

-- test that the scxml event i/o processor puts events in the correct queues.

return _scxml{ initial="s0",
   _state{ id="s0",
      _onentry{
         _send{ event="event1", type="scxml" }, -- default target is external queue 
         _send{ event="event2", target="#_internal", type="scxml" },
      },
      -- we should get the internal event first 
      _transition{ event="event1", target="fail" },
      _transition{ event="event2", target="s1" },
   },
    
   _state{ id="s1",
      _transition{ event="event1", target="pass" },
      _transition{ event="*", target="fail" },
   },
   
   _final{id='pass'},
   _final{id='fail'},
}

