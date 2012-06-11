-module(util_parsetransform).
-author("Konrad Gadek").
%-export([parse_transform/2]).
-compile(export_all).

%% I didn't reinvent the wheel. It's all here just a (re)implementation of ideas
%% in EMP1 from this tutorial: http://readlists.com/4b363742
%%
%%                               === Short FAQ ===
%%
%% 1) Why we append " " / " . " to the generated string?
%%     This is because erl_scan:tokens/3 returns {more, Continuation} when
%%     it's not sure. There was an example in tutor: "42." could become
%%     "42.3" or final instruction. That's why we add " " to assert scanner that
%%     that's the latter case.
%%     But here we add " . " to simplify case construct in tokenize/3 -- we never
%%     expect {more, Continuation} then.
%% 2) What is the airspeed velocity of unladden swallow?
%%     42.
%%
%%
%%             Break it down
%%             Stop! Lispy-macros time
%%                       -- MC Hammer

parse_transform([{attribute,_,file,{Filename, _}}|_] = AST, _CompileOptions) ->
    walk_ast(AST, Filename, []).

walk_ast([], _Filename, FinalAST) ->
    lists:flatten(lists:reverse(FinalAST));
walk_ast([ {attribute, Line, macro, {M, F, A}} | RestAST], Filename, FinalAST ) ->
    IntroduceMacroExpansion = lists:flatten(io_lib:format(" -file(\"~p.erl\", 1). ", [M])), % dunno the line
    BackToFile = lists:flatten(io_lib:format(" -file(~p, ~p). ", [Filename, Line])),
    Parsed = tokenize(lists:flatten([IntroduceMacroExpansion, apply(M,F,A) | BackToFile]),
                      Line, []),
    walk_ast(RestAST, Filename, [Parsed | FinalAST]); % we do lists:flatten/1 later
walk_ast([Node|RestAST], Filename, FinalAST % all the other cases (when we do nothing)
                                           ) ->
    walk_ast(RestAST, Filename, [Node | FinalAST]).

tokenize(ResultString, LineStart, ASTResult) ->
    case erl_scan:tokens([], ResultString, LineStart) of
        {done, {ok, Tokens, LineEnd}, StringRest} ->
            {ok, AST} = erl_parse:parse_form(Tokens),
            case StringRest of
                [] ->         lists:reverse([AST | ASTResult]); % nothing more to parse
                StringRest -> tokenize(StringRest, LineEnd, [AST | ASTResult])
            end%;
%        {more, _Continue} ->
%            lists:reverse(ASTResult)
    end.

