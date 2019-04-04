require("moonsc").import_tags()

-- Substatechart for test216.
-- When invoked, terminate returning done.invoke.
-- This proves that the invocation succeeded.
return _scxml{ initial="final", _final{ id="final" }}

