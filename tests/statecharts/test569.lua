require("moonsc").import_tags()

-- test that location field is found inside entry for
-- SCXML Event I/O processor in the lua data model.
-- The tests for the relevant event i/o processors will test
-- that it can be used to send events. 

return _scxml{ initial="s0", datamodel="lua",
   _state{ id="s0",
      _transition{ cond="_ioprocessors['scxml'].location", target="pass" },
      _transition{ target="fail" },
   },
  
   _final{id='pass'},
   _final{id='fail'},
}

