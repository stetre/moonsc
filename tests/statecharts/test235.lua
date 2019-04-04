require("moonsc").import_tags()

-- Test that done.invoke.id event has the right id.
-- the invoked child terminates immediately and should
-- generate done.invoke.foo   

return _scxml{ initial="s0",
   _state{ id="s0",
      _onentry{ _send{ event="timeout", delay="2s" }},
      _invoke{ type="scxml", id="foo",
         _content{ text=[[
            require("moonsc").import_tags()
            return _scxml{ initial="subFinal", _final{ id="subFinal" }}
         ]]},
      },
      _transition{ event="done.invoke.foo", target="pass" },
      _transition{ event="*", target="fail" },
   },  
 
   _final{id='pass'},
   _final{id='fail'},
}

