require("moonsc").import_tags()

-- Test that finalize markup runs before the event is processed.
-- The invoked process will return 2 in _event.data.aParam, so that
-- new value should be in force when we select the transitions.   

local SUB = [[
require("moonsc").import_tags()
return _scxml{ initial="subFinal",
   _final{ id="subFinal",
      _onentry{
         _send{ target="#_parent", event="childToParent",
            _param{ name="aParam", expr="2" },
         },
      },
   },
}]]

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1", expr="1" },
   },
     
   _state{ id="s0",
      _onentry{ _send{ event="timeout", delay="3s" }},
      _invoke{ type="scxml", 
         _content{ text=SUB }, 
         _finalize{ _assign{ location="var1", expr="_event.data.aParam" }},
      },
      _transition{ event="childToParent", cond="var1==2", target="pass" },
      _transition{ event="*", target="fail" },
   },  
 
   _final{id='pass'},
   _final{id='fail'},
}

