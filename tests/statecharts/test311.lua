require("moonsc").import_tags()

-- test that assignment to a non-existent location yields an error 

return _scxml{ initial="s0",
   _state{ id="s0",
      _onentry{
         _send{ event="timeout", delay="1s" },
         _assign{ location="invalid.location.is.this", expr="1" },
      },
      _transition{ event="error.execution", target="pass" }, 
      _transition{ event=".*", target="fail" },
   },
    
   _final{id='pass'},
   _final{id='fail'},
}

