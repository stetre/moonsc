require("moonsc").import_tags()

-- Test that we get the done.state.id event when all of a 
-- parallel elements children enter final states.

return _scxml{ initial="s1",
   _state{ id="s1", initial="s1p1",
      _onentry{ _send{ event="timeout", delay="1s" }},
      _transition{ event="timeout", target="fail" },
      _parallel{ id="s1p1",
         _transition{ event="done.state.s1p1", target="pass" },
         _state{ id="s1p11", initial="s1p111",
            _state{ id="s1p111", _transition{ target="s1p11final" }},
            _final{ id="s1p11final" },
         },
         _state{ id="s1p12", initial="s1p121",
            _state{ id="s1p121", _transition{ target="s1p12final" }},
            _final{ id="s1p12final" },
         },
      },
   },
   _final{id='pass'},
   _final{id='fail'},
}


