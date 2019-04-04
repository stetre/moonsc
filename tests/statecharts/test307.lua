require("moonsc").import_tags()

-- @@ MAH.....
-- With binding=late, in s0 we access a variable that isn't created
-- until we get to s1.  Then in s1 we access a non-existent substructure
-- of a variable. We use log tags to report the values that both operations
-- yield, and whether there are errors.
-- This is a MANUAL TEST, since the tester must report whether the output
-- is the same in the two cases 

return _scxml{ initial="s0", binding="late",
   _state{ id="s0",
      _onentry{
         _log{ label="entering s0 value of var1 is: ", expr="var1" },
         _raise{ event="foo" },
      },
      _transition{ event="error", target="s1", 
         _log{ label="error in state s0", expr="_event.name" },
      },
      _transition{ event="foo", target="s1",
         _log{ label="no error in s0" },
      },
   },
   
   _state{ id="s1",
      _datamodel{
         _data{ id="var1", expr="1" },
      },
      _onentry{
         _log{ expr="'entering s1, value of non-existent substructure of var1 is: '..var1" },
         _log{ expr="'entering s1, value of non-existent substructure of var1 is: '..var1.bar" },
            -- conf:varNonexistentStruct="1" },
         _raise{ event="bar" },
      },
      _transition{ event="error", target="pass", 
         _log{ label="error in state s1", expr="_event.name" },
      },
      _transition{ event="bar", target="pass",
         _log{ label="No error in s1" },
      },
   },
   --_final{ id="final" },
   _final{ id="pass" },
}

