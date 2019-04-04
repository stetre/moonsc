require("moonsc").import_tags()

-- Test that the 'initial' value of scxml is respected. 
-- We set the value to deeply nested non-default parallel siblings and
-- test that both are entered.

return _scxml{ initial='s11p112 s11p122',
   _state{ id='s0', _transition{ target='fail' }},
   _state{ id='s1',
      _onentry{ _send{ event='timeout', delay='1s' }},
      _transition{ event='timeout', target='fail' },
      _state{ id='s11', initial='s111',
         _state{ id='s111' },
         _parallel{ id='s11p1',
            _state{ id='s11p11', initial='s11p111',
               _state{ id='s11p111' },
               _state{ id='s11p112', _onentry{ _raise{ event='In_s11p112' }}},
            },
            _state{ id='s11p12', initial='s11p121',
               _state{ id='s11p121' },
               _state{ id='s11p122' , _transition{ event='In_s11p112', target='pass' }},
            }
         }
      }
   },
   _final{id='pass'},
   _final{id='fail'},
}

