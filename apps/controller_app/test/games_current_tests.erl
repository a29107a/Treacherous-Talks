%%%-------------------------------------------------------------------
%%% @copyright
%%% Copyright (C) 2011 by Bermuda Triangle
%%%
%%% Permission is hereby granted, free of charge, to any person obtaining a copy
%%% of this software and associated documentation files (the "Software"), to deal
%%% in the Software without restriction, including without limitation the rights
%%% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%%% copies of the Software, and to permit persons to whom the Software is
%%% furnished to do so, subject to the following conditions:
%%%
%%% The above copyright notice and this permission notice shall be included in
%%% all copies or substantial portions of the Software.
%%%
%%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%%% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
%%% THE SOFTWARE.
%%% @end
%%%-------------------------------------------------------------------
%%% @author Sukumar Yethadka <sbhat7@gmail.com>
%%%
%%% @doc Unit tests for getting current games of the given user
%%% @end
%%%
%%% @since : 17 Nov 2011 by Bermuda Triangle
%%% @end
%%%-------------------------------------------------------------------
-module(games_current_tests).

-include_lib("eunit/include/eunit.hrl").
-include_lib("datatypes/include/game.hrl").

-export([tests/1, success/3]).

tests([Callback, SessId, GameId]) ->
    [?_test(success(Callback, SessId, GameId))].
%%-------------------------------------------------------------------
%% Get current games tests
%%-------------------------------------------------------------------
success(Callback, SessId, GameId) ->
    ?debugMsg("GAMES_CURRENT TEST SUCCESS"),
    Data = dummy,
    Cmd = {games_current, {ok, SessId, Data}},
    Result = controller:handle_action(Cmd, Callback),
    {CmdRes, Games} = Result,
    ?assertEqual({games_current, success}, CmdRes),
    Game = hd(Games),
    ?assertEqual(GameId, Game#game.id),
    ?debugMsg("GAMES_CURRENT TEST SUCCESS finished").
