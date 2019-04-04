require("moonsc").import_tags()

-- Test that if the evaluation of _invoke{'s args causes an error,
-- the invocation is cancelled.  In this test, that means that we
-- don't get done.invoke before the timer goes off.

local SUB = [[return { tag="scxml", initial="subFinal", { tag="final", id="subFinal" }}]]

return _scxml{ initial="s0",
   _state{ id="s0",
      _onentry{ _send{ event="timer", delay="1" }},
      -- reference an invalid namelist 
      --_invoke{ type="scxml", namelist="foo", _content{ text=SUB}},
      _invoke{ type="scxml", namelist="invalid.namelist", _content{ text=SUB}},
      _transition{ event="timer", target="pass" },
      _transition{ event="done.invoke", target="fail" },
   }, 
     
   _final{id='pass'},
   _final{id='fail'},
}

