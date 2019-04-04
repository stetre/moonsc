require("moonsc").import_tags()

-- we test that using an invalid send type results in error.execution @@ not error.communication

return _scxml{ initial="s0",
   _state{ id="s0",
      _onentry{
         _send{ type="invalidsendtype", event="event1" },
         _send{ event="timeout" },
      }, 
      _transition{ event="error.execution", target="pass" },
      _transition{ event="*", target="fail" },
   }, 

   _final{id='pass'},
   _final{id='fail'},
}

