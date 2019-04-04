require("moonsc").import_tags()

-- Test that the done.state.id gets generated when we enter
-- the final state of a compound state

return _scxml{ initial="s1",
   _state{ id="s1", initial="s11",
      _onentry{ _send{ event="timeout", delay="1s" }},
      _transition{ event="timeout", target="fail" },
      _state{ id="s11", initial="s111",
         _transition{ event="done.state.s11", target="pass" },
         _state{ id="s111", _transition{ target="s11final" }},
         _final{ id="s11final" },
      }
   },
   _final{id='pass'},
   _final{id='fail'},
}
