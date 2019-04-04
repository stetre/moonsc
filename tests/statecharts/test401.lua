require("moonsc").import_tags()

-- Test that errors go in the internal event queue.
-- We send ourselves an external event foo, then perform an operationi
-- that raises an error. Then check that the error event is processed
-- first, even though it was raised second  


return _scxml{ initial="s0",
   _state{ id="s0",
      _onentry{
         _send{ event="foo" },
         -- @@assigning to a non-existent location should raise an error 
         -- _assign{ location="", expr="2" },
         _assign{ location="x", expr="notdefined()" },
      }, 
   _transition{  event="foo", target="fail" },
   _transition{  event="error", target="pass" },
   },
 
   _final{id='pass'},
   _final{id='fail'},
}

