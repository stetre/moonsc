require("moonsc").import_tags()

--  test that we can assign to any location in the datamodel.
--  In this case, we just test that we can assign to a substructure
--  (not the top level variable).  This may not be the most idiomatic
--  way to write the test 

return _scxml{ datamodel="lua",
   _datamodel{
      _data{ id="foo", expr="0" },
   },
   _script{ text=[[function testobject() return {bar=0} end]] },

   _state{ id="s0",
      _onentry{
         _assign{ location="foo", expr="testobject()" },
         -- try to assign to foo's bar property 
         _assign{ location="foo.bar", expr="1" },
         _raise{ event="event1" },
      },
      -- test that we have assigned to foo's bar property   
      _transition{ event="event1", cond="foo.bar==1", target="pass" },
      _transition{ event="*", target="fail" },
   },

   _final{id='pass'},
   _final{id='fail'},
}

