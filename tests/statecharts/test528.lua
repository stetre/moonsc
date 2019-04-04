require("moonsc").import_tags()

--  test that illegal 'expr' produces error.execution and empty event.data 

return _scxml{ initial="s0",
   _state{ id="s0", initial="s01",
      -- we should get the error before the done event 
      _transition{ event="error.execution", target="s1" },
      _transition{ event="done.state.s0", target="fail" },     

      _state{ id="s01",
         _transition{ target="s02" },
      },

      _final{ id="s02", _donedata{ _content{ expr="illegalExpr()" }}},
   },
 
   _state{ id="s1",
      -- if we get here, we received the error event. Now check that
      -- the done event has empty event.data 
      _transition{ event="done.state.s0", cond="_event.data==nil", target="pass" },
      _transition{ event="*", target="fail" },
   },

   _final{id='pass'},
   _final{id='fail'},
}

