require("moonsc").import_tags()

-- We test that the automatically generated id has the form stateid.platformid.   

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1" },
   },
     
   _state{ id="s0",
      _onentry{ _send{ event="timeout", delay="1s" }},
      _invoke{ type="scxml", idlocation="var1",
      _content{ text=[[
            require("moonsc").import_tags()
            -- when invoked, terminate returning done.invoke.
            -- This proves that the invocation succeeded.   
            return _scxml{  initial="subFinal", _final{ id="subFinal" }}
         ]]},
      },
      _transition{ event="*", target="s1" },
   },
   
   _state{ id="s1",
      -- cond = "is the first token of var1 equal to 's0' ?"
      _transition{ cond="string.match(var1, '^(.+)%.')=='s0'", target="pass" },
      _transition{ target="fail" },
   },

   _final{id='pass'},
   _final{id='fail'},
}

