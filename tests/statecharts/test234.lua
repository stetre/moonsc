require("moonsc").import_tags()

-- Test that only finalize markup in the invoking state runs. 
-- The first invoked process will return 2 in _event.data.aParam, while
-- second invoked process sleeps without returning any events. 
-- Only the first finalize should execute.  So when we get to s1 var1
-- should have value 2 but var2 should still be set to 1  

local SUB1 = [[
require("moonsc").import_tags()
return _scxml{ initial="subFinal1",
   _final{ id="subFinal1",
      _onentry{
         _send{ target="#_parent", event="childToParent",
            _param{ name="aParam", expr="2" },
         },
      },
   },
}]]

local SUB2 = [[
require("moonsc").import_tags()
return _scxml{ initial="sub0",
   _state{ id="sub0",
      _onentry{ _send{ event="timeout", delay="2s" }},
      _transition{ event="timeout", target="subFinal2" },
   },
   _final{ id="subFinal2" },
}]]


return _scxml{ initial="p0",
   _datamodel{
      _data{ id="var1", expr="1" },
      _data{ id="var2", expr="1" },
   },
   _parallel{ id="p0",
      _onentry{ _send{ event="timeout", delay="3s" }}, 
      _transition{ event="timeout", target="fail" },
      _state{ id="p01",
         _invoke{ type="scxml",
            _content{ text=SUB1 },
            _finalize{ _assign{ location="var1", expr="_event.data.aParam" }},
         },
         _transition{ event="childToParent", cond="var1==2", target="s1" },
         _transition{ event="childToParent", target="fail" },
      },
      _state{ id="p02",
         _invoke{ type="scxml",
            _content{ text = SUB2 },
            _finalize{ _assign{ location="var2", expr="_event.data.aParam" }},
         },
      },
   },  

   _state{ id="s1",
      _transition{ cond="var2==1", target="pass" },
      _transition{ target="fail" },
   },
  
   _final{id='pass'},
   _final{id='fail'},
}

