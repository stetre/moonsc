require("moonsc").import_tags()

return _scxml{ initial="s0",
   _state{ id="s0",
      _onentry{
         _send{  type="scxml", event="event", target="#_scxml_unknownsessionid" },
         _raise{ event="foo" },
      },
      _transition{ event="error.communication", target="pass" },
      _transition{ event="*", target="fail" },
   },
  
   _final{id='pass'},
   _final{id='fail'},
}

