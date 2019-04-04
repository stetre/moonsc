require("moonsc").import_tags()

-- test that we get done.invoke.  timeout indicates failure

return _scxml{ initial="s0",
   _state{ id="s0",
      _onentry{ _send{ event="timeout", delay="2s" }},
      _invoke{ type="scxml",
         _content{ text=[[
            require("moonsc").import_tags()
            return _scxml{ initial="subFinal", _final{ id="subFinal" }}
         ]]},
      },
      _transition{ event="done.invoke", target="pass" },
      _transition{ event="timeout", target="fail" },
   },
 
   _final{id='pass'},
   _final{id='fail'},
}


