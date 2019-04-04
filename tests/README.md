## MoonSC Tests


This directory contains a Lua/MoonSC port of most of the tests from the test suite
used in the [SCXML 1.0 Implementation Report](https://www.w3.org/Voice/2013/scxml-irp/).
Each test is written as a Lua script returning a statechart in its Lua-table form.

To execute all tests:

```sh
tests$ lua runtest.lua
```

To execute a single test, run the same script by passing it the file defining
its statechart, e.g.

```sh
tests$ lua runtest.lua statecharts/test551.lua  ;# executes test 551
```

The runtest.lua scripts is also a fairly comprehensive example of how to use
the callbacks in MoonSC.

