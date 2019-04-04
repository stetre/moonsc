require("moonsc").import_tags()

-- We test that cancel works.  We cancel delayed event1.
-- If cancel works, we get event2 first and pass. If we get event1
-- or an error first, cancel didn't work and we fail.  

return _scxml{ initial="s0",
   _state{ id="s0",
      _onentry{
         _send{ id="foo", event="event1", delay="1" },
         _send{ event="event2", delay="1.5" },
         _cancel{ sendid="foo" },
      }, 
      _transition{ event="event2", target="pass" },
      _transition{ event="*", target="fail" },
   }, 

   _final{id='pass'},
   _final{id='fail'},
}

