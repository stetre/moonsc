require("moonsc").import_tags()

-- Test that default initial state is first in document order.
-- If we enter s0 first we succeed, if s1, failure.

return _scxml{
   _state{id='s0', _transition{target='pass'}},
   _state{id='s1', _transition{target='fail'}},
   _final{id='pass'},
   _final{id='fail'},
}

