require("moonsc").import_tags()
-- Substatechart: when invoked, just terminates.
return _scxml{ initial="final", _final{ id="final" }}

