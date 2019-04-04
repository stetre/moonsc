require("moonsc").import_tags()

-- Test that default initial states are entered when a compound state
-- is entered. First we test the 'initial' attribute, then the initial
-- element, then default to the first child in document order.  
-- If we get to s01111 we succeed, if any other state, failure.

return _scxml{ initial="s1",

   _state{ id="s1", initial="s11p112 s11p122",
      _onentry{ _send{ event="timeout", delay="1s" }},
      _transition{ event="timeout", target="fail"},
      _state{ id="s11", initial="s111",
         _state{ id="s111" },
         _parallel{ id="s11p1",
            _state{ id="s11p11", initial="s11p111",
               _state{ id="s11p111" },
               _state{ id="s11p112", _onentry{ _raise{ event="In_s11p112" }}},
            },
            _state{ id="s11p12", initial="s11p121",
               _state{ id="s11p121" },
               _state{ id="s11p122", _transition{ event="In_s11p112", target="s2" }},
            },
         }
      }
   },

   _state{ id="s2",
      _initial{ _transition{ target="s21p112 s21p122" }},
      _transition{ event="timeout", target="fail"},
      _state{ id="s21", initial="s211",
         _state{ id="s211" },
         _parallel{ id="s21p1",
            _state{ id="s21p11", initial="s21p111",
               _state{ id="s21p111" },
               _state{ id="s21p112", _onentry{ _raise{ event="In_s21p112" }}},
            },
            _state{ id="s21p12", initial="s21p121",
               _state{ id="s21p121" },
               _state{ id="s21p122", _transition{ event="In_s21p112", target="s3" }}
            },
         }
      }
   },
      
   _state{ id="s3",
      _transition{ target="fail" },
      _state{ id="s31",
         _state{ id="s311", 
            _state{ id="s3111", _transition{ target="pass" }},
            _state{ id="s3112" },
         _state{ id="s312" },
         },
      _state{ id="s32" },
      }
   },
   _final{id='pass'},
   _final{id='fail'},
}

