require("moonsc").import_tags()
 
-- test that event attribute of send sets the name of the event

return _scxml{ initial="s0",
   _state{ id="s0",
      _onentry{
         _send{  type="scxml", event="s0Event" },
      },
      _transition{ event="s0Event", target="pass" },
      _transition{ event="*", target="fail" },
   },
  
   _final{id='pass'},
   _final{id='fail'},
}

