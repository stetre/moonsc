require("moonsc").import_tags()

-- we test that if type is not provided <send> uses the scxml
-- event i/o processor.  The only way to tell what processor was
-- used is to look at the origintype of the resulting event  

return _scxml{ initial="s0",
   _state{ id="s0",
      _onentry{
         _send{  event="event1" },
         _send{ event="timeout" },
      },
      _transition{ event="event1", cond="_event.origintype=='scxml'", target="pass" },
      _transition{ event="*", target="fail" },
   },
 
   _final{id='pass'},
   _final{id='fail'},
}

