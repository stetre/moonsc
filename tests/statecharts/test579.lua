require("moonsc").import_tags()

-- Test that default history content is executed correctly.
-- The Process MUST execute any executable content in the transition
-- after the parent state's onentry handlers, and, in the case where
-- the history pseudo-state is the target of an <initial> transition,
-- the executable content inside the <initial> transition.
-- However the Processor MUST execute this content only if there is no
-- stored history.  Once the history state's parent state has been
-- visited and exited, the default history content must not be executed.

return _scxml{ initial="s0",
   _state{ id="s0",
      _datamodel{
         _data{ id="var1", expr="0" },
      },
      _initial{ _transition{ target="sh1", _raise{ event="event2" } }},
      _onentry{
         _send{ delay="1", event="timeout" },
         _raise{ event="event1" },
      },
      _onexit{ _assign{ location="var1", expr="var1+1" }},
      _history{ id="sh1", _transition{ target="s01", _raise{ event="event3" }}},
      _state{ id="s01",
         _transition{ event="event1", target="s02" },
         _transition{ event="*", target="fail" },
      },
      _state{ id="s02",
         _transition{ event="event2", target="s03" },
         _transition{ event="*", target="fail" },
      },
      _state{ id="s03",
         _transition{ cond="var1==0", event="event3", target="s0" },
         _transition{ cond="var1==1", event="event1", target="s2" },
         _transition{ event="*", target="fail" },
      },
   },

   _state{ id="s2",
       _transition{ event="event2", target="s3" },
       _transition{ event="*", target="fail" },
   },

   _state{ id="s3",
       _transition{ event="event3", target="fail" },
       _transition{ event="timeout", target="pass" },
   },

   _final{id='pass'},
   _final{id='fail'},
}

