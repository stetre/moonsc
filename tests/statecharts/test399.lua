require("moonsc").import_tags()

-- Test that the event name matching works correctly, including prefix
-- matching and the fact that the event attribute of transition may contain
-- multiple event designators.

return _scxml{ initial="s0",
   _state{ id="s0", initial="s01",
      _onentry{ _send{ event="timeout", delay="2s" }}, 
      -- this will catch the failure case
      _transition{ event="timeout", target="fail" },
      _state{ id="s01", _onentry{ _raise{ event="foo" }}, 
      -- test that an event can match against a transition with multiple descriptors
      _transition{ event="foo bar", target="s02" }}, 
      _state{ id="s02", _onentry{ _raise{ event="bar" }}, 
      -- test that an event can match the second descriptor as well
      _transition{ event="foo bar", target="s03" }}, 
      _state{ id="s03",
         _onentry{ _raise{ event="foo.zoo" }}, 
         -- test that a prefix descriptor matches
         _transition{ event="foo bar", target="s04" },
      }, 
      _state{ id="s04", 
         _onentry{ _raise{ event="foos" }}, 
         -- test that only token prefixes match
         _transition{ event="foo", target="fail" },
         _transition{ event="foos", target="s05" },
      },
      _state{ id="s05",
         _onentry{ _raise{ event="foo.zoo" }}, 
         -- test that .* works at the end of a descriptor
         _transition{ event="foo.*", target="s06" },
      },
      _state{ id="s06",
         _onentry{ _raise{ event="foo" }}, 
         -- test that "*", works by itself
         _transition{ event="*", target="pass" },
      }, 
   },
 
   _final{id='pass'},
   _final{id='fail'},
}

