require("moonsc").import_tags()

-- The processor should  reject this document because it can't
-- download the script. Therefore  we fail if it runs at all.
-- This test is valid only for datamodels that support scripting.

return _scxml{ initial="s0",
   _script{ src="file:badscriptname.lua" },
   _state{ id="s0",
      _transition{ target="fail" },
   },
   
   _final{id='pass'},
   _final{id='fail'},
}

