require("moonsc").import_tags()

-- We test that sendidexpr works with cancel. If it takes the most recent
-- value of var1, it should cancel delayed event1. Thus we get event2 first
-- and pass. If we get event1 or an error first, cancel didn't work and we fail.  

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1", expr="'bar'" },
   },
   
   _state{ id="s0",
      _onentry{
         _send{ id="foo", event="event1", delay="1" },
         _send{ event="event2", delay="1.5" },
         _assign{ location="var1", expr="'foo'" },
         _cancel{ sendidexpr="var1" },
      },
      _transition{ event="event2", target="pass" },
      _transition{ event="*", target="fail" },
   },

   _final{id='pass'},
   _final{id='fail'},
}

