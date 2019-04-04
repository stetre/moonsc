require("moonsc").import_tags()

-- test that assigment to a non-declared var causes an error.
-- the transition on foo catches the case where no error is raised 

return _scxml{ initial="s0",
   _state{ id="s0",
      _onentry{
         _assign{ location="foo.bar.baz", expr="var1" },
         _raise{ event="foo" },
      },
      _transition{ event="error.execution", target="pass" },
      _transition{ event="*", target="fail" },
   },

   _final{id='pass'},
   _final{id='fail'},
}

