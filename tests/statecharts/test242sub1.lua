require("moonsc").import_tags()
-- when invoked, just terminate.

return _scxml{ initial="final",
   _final{ id="final" }
}


