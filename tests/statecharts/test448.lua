require("moonsc").import_tags()

-- Test that all lua objects are placed in a single global scope 

return _scxml{ datamodel="lua",
   _state{ id="s0",
      -- test that a parent state can access a variable defined in a child 
      _transition{ cond="var1==1", target="s1" },
      _transition{ target="fail" },
      _state{ id="s01",
         _datamodel{
            _data{ id="var1", expr="1" },
         },
      },
   }, 

   _state{ id="s1", initial="s01p",  
      _parallel{ id="s01p",
         _state{ id="s01p1",
            -- test that we can access a variable defined in a parallel sibling state 
           _transition{ cond="var2==1", target="pass" },
           _transition{ target="fail" },
         },
         _state{ id="s01p2",
            _datamodel{
               _data{ id="var2", expr="1" },
            },
         },
      },
   },
 
   _final{id='pass'},
   _final{id='fail'},
}

