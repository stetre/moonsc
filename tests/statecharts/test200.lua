require("moonsc").import_tags()

-- we test that the processor supports the scxml event i/o processor 

return _scxml{ initial="s0",
   _state{ id="s0",
      _onentry{
         --@@ _send{ type="http://www.w3.org/TR/scxml/#SCXMLEventProcessor", event="event1" },
         _send{ type="scxml", event="event1" },
         _send{ event="timeout" },
      }, 
      _transition{ event="event1", target="pass" },
      _transition{ event="*", target="fail" },
   }, 

   _final{id='pass'},
   _final{id='fail'},
}

