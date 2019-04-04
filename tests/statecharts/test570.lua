require("moonsc").import_tags()

-- Test that we generate done.state.id when all a parallel state's
-- children are in final states

return _scxml{ initial="p0",
   _datamodel {
      _data{ id="Var1", expr="0" },
   },

   _parallel{ id="p0",
      _onentry{
         _send{ event="timeout", delay="2s" },
         _raise{ event="e1" },
         _raise{ event="e2" },
      },
      -- record that we get the first done event
      _transition{ event="done.state.p0s1", _assign{ location="Var1", expr="1" }},
      -- we should get the second done event before done.state.p0
      _transition{ event="done.state.p0s2", target="s1" },
      _transition{ event="timeout", target="fail" },
      _state{ id="p0s1", initial="p0s11",
         _state{ id="p0s11", _transition{ event="e1", target="p0s1final" }},
         _final{ id="p0s1final" },
      },
      _state{ id="p0s2", initial="p0s21",
         _state{ id="p0s21", _transition{ event="e2", target="p0s2final" }},
         _final{ id="p0s2final" },
      },
   },
 
   _state{ id="s1",
      -- if we get done.state.p0, success
      _transition{ event="done.state.p0", cond="Var1==1", target="pass" },
      _transition{ event="*", target="fail" },
   },

   _final{id='pass'},
   _final{id='fail'},
}
