require("moonsc").import_tags()

-- We test that srcexpr is evaluated at runtime.
-- If the original value of var1 is used, the invocation
-- will fail (assuming that there is no script named 'foo').
-- If the runtime value is used, the invocation will succeed 

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1", expr="'foo'" },
   },
   _state{ id="s0",
      _onentry{
         _send{ event="timeout", delay="5s" },
         _assign{ location="var1", expr="'file:statecharts/test216sub1.lua'" },
      },
      _invoke{ srcexpr="var1", type="scxml" },
      _transition{ event="done.invoke", target="pass" },
      _transition{ event="*", target="fail" }, 
   },

   _final{id='pass'},
   _final{id='fail'},
}

