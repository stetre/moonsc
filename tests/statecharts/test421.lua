require("moonsc").import_tags()

-- Test that internal events take priority over external ones,
-- and that the processor keeps pulling off internal events until
-- it finds one that triggers a transition

return _scxml{ initial="s1",
   _state{ id="s1", initial="s11",
      _onentry{
         _send{ event="externalEvent" },
         _raise{ event="internalEvent1" },
         _raise{ event="internalEvent2" },
         _raise{ event="internalEvent3" },
         _raise{ event="internalEvent4" },
      },
      _transition{ event="externalEvent", target="fail" },
      _state{ id="s11", _transition{ event="internalEvent3", target="s12" }},
      _state{ id="s12", _transition{ event="internalEvent4", target="pass" }},
   },
   _final{id='pass'},
   _final{id='fail'},
}

