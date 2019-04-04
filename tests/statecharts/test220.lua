require("moonsc").import_tags()

-- we test that the scxml type is supported.

return _scxml{ initial="s0",
   _state{ id="s0",
      _onentry{ _send{ event="timeout", delay="5s" }},
      _invoke{ type="scxml", -- type="http://www.w3.org/TR/scxml/"
         _content{ text=[[
            require("moonsc").import_tags()
            -- when invoked, terminate returning done.invoke.
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

