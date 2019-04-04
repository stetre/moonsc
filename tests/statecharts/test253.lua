require("moonsc").import_tags()

-- Test that the scxml event processor is used in both directions.
-- If child process uses the scxml event i/o processor to communicate
-- with us, send it an event. It will send back success if this process
-- uses the scxml processor to send the message to it, otherwise failure.

-- Sub: inform parent we're running then wait for it to send us an event.
-- If it uses the scxml event i/o processor to do so, return success,
-- otherwise return failure.   
local SUB = [[
require("moonsc").import_tags()
return _scxml{ initial="sub0",
   _datamodel{
      _data{ id="var2" },
   },
   _state{ id="sub0",
      _onentry{ _send{ target="#_parent", event="childRunning" }},
      _transition{ event="parentToChild", target="sub1",
         _assign{ location="var2", expr="_event.origintype" },
      },
   },
   _state{ id="sub1",
      _transition{ cond="var2=='scxml'", target="subFinal",
         _send{ target="#_parent", event="success" },
      },
      _transition{ cond="var2=='scxml'", target="subFinal",
         _send{ target="#_parent", event="success" },
      },
      _transition{ target="subFinal",
         _send{ target="#_parent", event="failure" },
      },
   },
   _final{ id="subFinal" },
}]]

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1" },
   },
     
   _state{ id="s0", initial="s01",
      _onentry{ _send{ event="timeout", delay="2s" }},
      _transition{ event="timeout", target="fail" },
      _invoke{ type="scxml", id="foo",  _content{ text=SUB }},
      _state{ id="s01",
         _transition{ event="childRunning", target="s02",
            _assign{ location="var1", expr="_event.origintype" },
         },
      },
      _state{ id="s02",
         _transition{ cond="var1=='scxml'", target="s03",
            _send{ target="#_foo", event="parentToChild" },
         },
         _transition{ cond="var1=='scxml'", target="s03",
            _send{ target="#_foo", event="parentToChild" },
         },
         _transition{ target="fail" },
      },      
      _state{ id="s03",
         _transition{ event="success", target="pass" },
         _transition{ event="fail", target="fail" },
      }, 
   },
 
   _final{id='pass'},
   _final{id='fail'},
}

