require("moonsc").import_tags()

-- We test that the processor doesn't change the message.
-- We can't test that it never does this, but at least we can check
-- that the event name and included data are the same as we sent.  

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1" },
   },
   
   _state{ id="s0",
      _onentry{
         _send{  event="event1", _param{ name="aParam", expr="'foobar'" }},
         _send{ event="timeout" },
      },
      _transition{ event="event1", target="s1",
        _assign{ location="var1", expr="_event.data.aParam" },
      },
      _transition{ event="*", target="fail" },
   },

   _state{ id="s1",
      _transition{ cond="var1=='foobar'", target="pass" },
      _transition{ target="fail" },
   },

   _final{id='pass'},
   _final{id='fail'},
}

