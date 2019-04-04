require("moonsc").import_tags()

-- simple test of the in() predicate

return _scxml{ initial="p",
   _parallel{ id="p",
      _state{ id="s0",
         _transition{ cond="In('s1')", target="pass"  },
         _transition{ target="fail" },
      }, 
      _state{ id="s1"  },
   }, 
   _final{id='pass'},
   _final{id='fail'},
}

