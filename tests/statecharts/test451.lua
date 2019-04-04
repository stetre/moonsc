require("moonsc").import_tags()

-- simple test of the In() predicate 

return _scxml{ datamodel="lua", initial="p",
   _parallel{ id="p",
      _state{ id="s0",
         _transition{ cond="In('s1')", target="pass" }, 
         _transition{ target="fail" },
      },
      _state{ id="s1" }, 
   },
    
   _final{id='pass'},
   _final{id='fail'},
}

