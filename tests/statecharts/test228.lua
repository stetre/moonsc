require("moonsc").import_tags()

-- Test that the invokeid is included in events returned
-- from the invoked process. 

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1" },
   },
     
   _state{ id="s0",
      _onentry{ _send{ event="timeout", delay="3s" }},
      _invoke{ type="scxml", id="foo",
         _content{ text=[[
            require("moonsc").import_tags()
            return _scxml{ initial="subFinal", _final{ id="subFinal" }}
         ]]},
      },
      _transition{ event="done.invoke", target="s1",
         _assign{ location="var1", expr="_event.invokeid" },
      },
      _transition{ event="*", target="fail" },
   },

   _state{ id="s1",
      _transition{ cond="var1=='foo'", target="pass" },
      _transition{ target="fail" },
   },

   _final{id='pass'},
   _final{id='fail'},
}

