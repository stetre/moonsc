require("moonsc").import_tags()

-- Test that the state machine is put into the configuration specified
-- by the initial element, without regard to any other defaults.
-- we should start off in s2p111 and s2p122.  the atomic states we should
-- not enter all have immediate transitions to failure in them 

return _scxml{ initial="s2p112 s2p122",
   _state{ id="s1",
      _transition{ target="fail" },
   }, 
   _state{ id="s2", initial="s2p1",
      _parallel{ id="s2p1",
         -- this transition will be triggered only if we end up in an illegal configuration
         -- where we're in  either s2p112 or s2p122, but not both of them 
        _transition{ target="fail" },
         _state{ id="s2p11", initial="s2p111",
            _state{ id="s2p111",
               _transition{ target="fail" },
            }, 
            _state{ id="s2p112",
               _transition{ cond="In('s2p122')", target="pass" },
            }, 
         }, -- end s2p11 
         _state{ id="s2p12", initial="s2p121",
            _state{ id="s2p121",
               _transition{ target="fail" },
            }, 
            _state{ id="s2p122",
               _transition{ cond="In('s2p112')", target="pass" },
            }, 
         }, 
      },
   },  -- end s2 

   _final{id='pass'},
   _final{id='fail'},
}

