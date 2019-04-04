require("moonsc").import_tags()

-- We test that states are removed from the active states list as they
-- are exited.  When s01's onexit handler fires, s011 should not be on
-- the active state list, so in(S011) should be false, and event1 should
-- not be raised.  Therefore the timeout should fire to indicate success   

return _scxml{ initial="s0",
   _state{ id="s0", initial="s01",
      _onentry{ _send{ event="timeout", delay="1" }}, 
      _transition{ event="timeout", target="pass"  },
      _transition{ event="event1", target="fail" },
      _state{ id="s01", initial="s011",
         _onexit{ 
            _if{ cond="In('s011')", _raise{ event="event1" }}, 
         }, 
         _state{ id="s011", _transition{ target="s02" }}, 
      },
      _state{ id="s02" },
   },
   _final{id='pass'},
   _final{id='fail'},
}


