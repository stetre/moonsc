require("moonsc").import_tags()

-- Test that the origin field of an external event contains a URL that
-- lets you send back to the originator. 
-- In this case it's the same session, so if we get bar we succeed 

return _scxml{ initial="s0", name="machineName",  
   _state{ id="s0",
      _onentry{ _send{ event="foo" }},
      _transition{ event="foo", target="s1",
         -- send to sender:
         _send{ event='bar', typeexpr="_event.origintype", targetexpr="_event.origin" },
         _log{ expr=[['origintype='.._event.origintype..' origin='.._event.origin]] },
      },
      _transition{ event="*", target="fail"  },
   },
   
   _state{ id="s1",
      _onentry{ _send{ event="baz" }},
      _transition{ event="bar", target="pass" },
      _transition{ event="*", target="fail" },
   },
      
   _final{id='pass'},
   _final{id='fail'},
}

