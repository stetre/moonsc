require("moonsc").import_tags()

-- define var1 with default value 0.  Parent will invoke this process
-- setting var1 = 1.  Return event1 if var1 == 1, event0 otherwise 

return _scxml{ initial="s0",
   _datamodel{
      _data{ id="var1", expr="0" },
   },
   _state{ id="s0",
      _transition{ cond="var1==1", target="final",
         _send{ target="#_parent", event="event1" },
      },
      _transition{ target="final",
         _send{ target="#_parent", event="event0" },
      },
   },
   _final{ id="final" },
}

