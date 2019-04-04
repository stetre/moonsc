require("moonsc").import_tags()

-- This is basically just a test that invoke works correctly
-- and that you can pass data to the invoked process.
-- If the invoked session finds var1=true, it exits, signalling
-- success. otherwise it will hang and the timeout in this doc
-- signifies failure.

return _scxml{ initial="s0",
   _state{ id="s0",
      _onentry{ _send{ event="timeout", delay="3s" }},
      _invoke{ type="scxml", src="file:statecharts/test226sub1.lua",
         _param{ name="var1", expr="true" },
      },
      _transition{ event="varBound", target="pass" },
      _transition{ event="*", target="fail" },
   },

   _final{id='pass'},
   _final{id='fail'},
}

