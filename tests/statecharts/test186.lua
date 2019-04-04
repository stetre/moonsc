require("moonsc").import_tags()

-- we test that <send> evals its args when it is evaluated,
-- not when the delay interval expires and the message is actually sent.
-- If it does, aParam will have the value of 1 (even though var1 has been
-- incremented in the interval.) If var2 ends up == 1, we pass. 
-- Otherwise we fail  

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1", expr="1" },
      _data{ id="var2" },
   },
  
   _state{ id="s0",
      _onentry{
         _send{ event="event1", delay="1", _param{ name="aParam", expr="var1" }},
         _assign{ location="var1", expr="2" },
      },
      _transition{ event="event1", target="s1", 
         _assign{ location="var2", expr="_event.data.aParam" },
      },
      _transition{ event="*", target="fail" },
   },

   _state{ id="s1",
      _transition{ cond="var2==1", target="pass" },
      _transition{  target="fail" },
   },
       
   _final{id='pass'},
   _final{id='fail'},
}

