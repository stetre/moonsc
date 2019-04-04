require("moonsc").import_tags()

-- Test that the state machine halts when it enters a top-level final state.
-- Since the initial state is a final state, this machine should halt immediately
-- without processing "event1" which is raised in the final state's on-entry handler.
-- THIS IS A MANUAL TEST since there is no platform-independent way to test that
-- event1 is not processed

return _scxml{ initial="pass s1",
   _state{ id="s1", _transition{ event='event1', _log{expr="'TEST FAILED'"}}}, --@@
   _final{ id="pass", _onentry{ _raise{ event="event1" }}},
}

