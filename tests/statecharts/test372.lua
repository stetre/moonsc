require("moonsc").import_tags()

-- Test that entering a final state generates done.state.parentid after
-- executing the onentry elements.  
-- Var1 should be set to 2 (but not 3) by the time the event is raised.

return _scxml{
   _datamodel{
      _data{ id='Var1', expr="1" },
   },
   _state{ id="s0", initial="s0final",
      _onentry{ _send{ event="timeout", delay="1s" }},
      _transition{ event="done.state.s0", cond="Var1==2", target="pass" },
      _transition{ event="*", target="fail" },
      _final{ id="s0final",
         _onentry{ _assign{ location="Var1", expr="2" }},
         _onexit{ _assign{ location="Var1", expr="3" }},
      }
   },
   _final{id='pass'},
   _final{id='fail'},
}

