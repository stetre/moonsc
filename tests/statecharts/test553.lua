require("moonsc").import_tags()

-- we test that the processor does not dispatch the event if evaluation
-- of _send{'s args causes an error..  

return _scxml{ initial="s0",
   _state{ id="s0",
      _onentry{
         _send{ event="timeout", delay="1" },
         _send{ event="event1", namelist="foo()" }, -- generate an invalid namelist @@
         --_send{ event="event1", namelist="foo" }, -- <<-- should be invalid but is not @@
      },
      -- if we get the timeout before event1, we assume that event1 hasn't been sent
      -- We ignore the error event here because this assertion doesn't mention it    
      _transition{ event="timeout", target="pass" },
      _transition{ event="event1", target="fail" },
   },
 
   _final{id='pass'},
   _final{id='fail'},
}

