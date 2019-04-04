require("moonsc").import_tags()

-- We test that typexpr is evaluated at runtime.
-- If the original value of var1 is used, the invocation will
-- fail (test215sub1.scxml is not of type 'foo', even if the
-- platform supports foo as a type). If the runtime value is
-- used, the invocation will succeed 

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1", expr="'foo'" },
   },
   
   _state{ id="s0",
      _onentry{
         _send{ event="timeout", delay="5s" },
         _assign{ location="var1", expr="'scxml'" },
      },
      _invoke{ typeexpr="var1", 
            _content{ text=[[
               require("moonsc").import_tags()
               -- When invoked, terminate returning done.invoke.
               -- This proves that the invocation succeeded.   
               return _scxml{ initial="subFinal", _final{ id="subFinal" }}
            ]]},
      },
      _transition{ event="done.invoke", target="pass" },
      _transition{ event="*", target="fail" }, 
   },

   _final{id='pass'},
   _final{id='fail'},
}

