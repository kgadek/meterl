-module(test).
-export([tester/0]).
-compile({parse_transform, util_parsetransform}).

-macro({util_test, test, []}).

tester() ->
    test().

