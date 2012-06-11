-module(test).
-export([tester/0]).
-compile({parse_transform, util_parsetransform}).

test() -> A = 2,
          B = 3,
          A + B.

-file("test.erl", 6).
tester() ->
    test().

