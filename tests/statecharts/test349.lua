require("moonsc").import_tags()

-- test that value in origin field can be used to send an
-- event back to the sender 

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1" },
   },
  
   _state{ id="s0",
      _onentry{ _send{ type="scxml", event="s0Event" }},
      _transition{ event="s0Event", target="s2",
         _log{ expr="_event.origin"},
         _assign{ location="var1", expr="_event.origin" },
      },
      _transition{ event="*", target="fail" },
   },

   _state{ id="s2",
      _onentry{ _send{ type="scxml", targetexpr="var1", event="s0Event2" }},
      _transition{ event="s0Event2", target="pass" },
      _transition{ event="*", target="fail" },
   },
  
   _final{id='pass'},
   _final{id='fail'},
}

