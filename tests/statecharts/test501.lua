require("moonsc").import_tags()

-- test that the location entry for the SCXML Event I/O processor can be used as the target for an event 

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1", expr="_ioprocessors.scxml.location" },
   },
  
   _state{ id="s0",
      _onentry{
         _send{ targetexpr="var1", event="foo" },
         _send{ event="timeout", delay="2s" },
      },
      _transition{ event="foo", target="pass" },
      _transition{ event="*", target="fail" },
   },
  
   _final{id='pass'},
   _final{id='fail'},
}

