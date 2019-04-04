require("moonsc").import_tags()

-- test that an internal transition whose targets are not proper
-- descendants of its source state behaves like an external transition 

return _scxml{ initial="s1",
   _datamodel{
      _data{ id="var1", expr="0"  }, -- how often we have exited s2 
      _data{ id="var2", expr="0"  }, -- how often we have exited s21 
      _data{ id="var3", expr="0"  }, -- how often the transition for foo has been taken 
   }, 
    
   _state{ id="s1",
      _onentry{
         _raise{ event="foo" },
         _raise{ event="bar" },
      }, 
      _transition{ target="s2" },
   }, 

   _state{ id="s2", initial="s21",
      _onexit{ _assign{ location="var1", expr="var1+1" }}, 
      _transition{ event="foo", type="internal", target="s2",
         _assign{ location="var3", expr="var3+1" },
      }, 
      -- make sure the transition on foo was actually taken  
      _transition{ event="bar", cond="var3==1", target="s3" },
      _transition{ event="bar", target="fail" },
  
      _state{ id="s21",
         _onexit{ _assign{ location="var2", expr="var2+1" }}, 
      }, 
   },
  
   _state{ id="s3",
      -- make sure that s2 was exited twice 
      _transition{ cond="var1==2", target="s4" },
      _transition{ target="fail" },
   }, 
 
   _state{ id="s4",
      -- make sure that s21 was exited twice 
      _transition{ cond="var2==2", target="pass" },
      _transition{ target="fail" },
   }, 
  
   _final{id='pass'},
   _final{id='fail'},
}

