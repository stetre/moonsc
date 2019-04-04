require("moonsc").import_tags()

-- Test that eventless transitions take precedence over event-driven ones

return _scxml{ initial="s1",
   _state{ id="s1",
      _onentry{
         _raise{ event="internalEvent" },
         _send{ event="externalEvent" },
      },
      _transition{ event="*", target="fail" },
      _transition{ target="pass" },
   },

   _final{id='pass'},
   _final{id='fail'},
}


