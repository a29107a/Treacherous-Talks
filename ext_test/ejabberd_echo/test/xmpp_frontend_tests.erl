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
%%%==================================================================
%%% @doc
%%% Integration tests of the Treacherous Talks game system via
%%%  the xmpp_frontend application using exmpp as an xmpp client.
%%%
%%% This assumes the xmpp_frontend is running a server on the
%%% hostname 'localhost' and is connected to a backend release.
%%%
%%%==================================================================

-module(xmpp_frontend_tests).

-include_lib("eunit/include/eunit.hrl").
-include_lib("exmpp/include/exmpp_client.hrl").

-define(NOW_UNIV, calendar:now_to_universal_time(os:timestamp())).

%%-------------------------------------------------------------------
%% @doc
%% Some macros which define predefined messages and value for running
%% these tests.
%%-------------------------------------------------------------------
-define(SERVICE_BOT, "service@tt.localhost").

%% Password that xmpp client users will use
-define(XMPP_PASSWORD, "password").


%% ------------------------------------------------------------------
%% Requests
%%-------------------------------------------------------------------
-define(ECHO_TEST_MSG, "Echo test message").
-define(REGISTER_COMMAND_CORRECT(Nick),
"REGISTER
NICKNAME: " ++ Nick ++ "
PASSWORD: pass
FULLNAME: Full Name
EMAIL: sth@sth
END").
-define(LOGIN_COMMAND_CORRECT(Nick),
"LOGIN
NICKNAME: " ++ Nick ++ "
PASSWORD: pass
END").
-define(LOGIN_COMMAND_BAD_PASSWORD(Nick),
"LOGIN
NICKNAME: " ++ Nick ++ "
PASSWORD: wrongpwd
END").
-define(LOGIN_COMMAND_BAD_NICK,
"LOGIN
NICKNAME: nonexistentuser
PASSWORD: pass
END").
-define(UPDATE_COMMAND_CORRECT(Session),
"UPDATE
SESSION: " ++ Session ++ "
PASSWORD: pass
FULLNAME: Full Nameeee
EMAIL: sth@sth
END").
-define(UPDATE_COMMAND_MISSING_FIELD(Session),
"UPDATE
PASSWORD: pass
FULLNAME: Full Nameeee
EMAIL: ath@sth
END").
-define(CREATE_COMMAND_CORRECT(Session, Press, Waittime),
"CREATE
SESSION: " ++ Session ++ "
GAMENAME: bob
PRESSTYPE: " ++ Press ++"
ORDERCIRCLE: 1D
RETREATCIRCLE: 1D
GAINLOSTCIRCLE: 1D
WAITTIME: " ++ Waittime ++"
END").
-define(CREATE_COMMAND_MISSING_FIELDS(Session),
"CREATE
ORDERCIRCLE: 1
RETREATCIRCLE: 1
GAINLOSTCIRCLE: 1
WAITTIME: 1
END").
-define(RECONFIG_COMMAND(Session, GameID),
"RECONFIG
SESSION: " ++ Session ++ "
GAMEID: " ++ GameID ++ "
PRESSTYPE: grey
ORDERCIRCLE: 2D
END").
-define(JOIN_GAME_COMMAND(Session, GameID, Country),
"JOIN
SESSION: " ++ Session ++ "
GAMEID: " ++ GameID ++ "
COUNTRY: " ++ Country ++ "
END").
-define(GAME_OVERVIEW_COMMAND(Session, GameID),
"OVERVIEW
SESSION: " ++ Session ++ "
GAMEID: " ++ GameID ++ "
END").

-define(GAME_ORDER_COMMAND(Session, GameID),
"sddfaadfaff

ORDER

SESSION: " ++ Session ++ "
GAMEID: " ++ GameID ++ "

A Lon-Nrg
A Lon-Nrg
A Lon -> Nrg nc
Army Lon move Nrg

END
adfadfasdfaldfad").

-define(GAME_ORDER_COMMAND_WRONG(Session, GameID),
"sddfaadfaff

ORDER

SESSION: " ++ Session ++ "
GAMEID: " ++ GameID ++ "

A Nrg
A Lon-Nrg
A Lon -> Nrg nc
Army Lon move Nrg

END
adfadfasdfaldfad").

-define(SEND_OFF_GAME_MSG(Session, ToNick, Msg),
"MESSAGE
SESSION: " ++ Session ++ "
TO: " ++ ToNick ++ "
CONTENT:" ++ Msg ++ "
END").

-define(SEND_GAME_MSG(Session, GameID, ToCountry, Msg),
"MESSAGE
SESSION: " ++ Session ++ "
GAMEID: " ++ GameID ++ "
TO: " ++ ToCountry ++ "
CONTENT:" ++ Msg ++ "
END").

-define(GAME_MSG, "in game message for one country :-)").

-define(GAME_VIEW_COMMAND(Session),
"VIEWCURRENTGAMES
SESSION: " ++ Session ++ "
END").
-define(GAME_SEARCH_COMMAND(Session, GameID),
"SEARCH
SESSION: " ++ Session ++ "
GAMEID: " ++ GameID ++ "
END").
-define(GAME_SEARCH_COMMAND_EMPTY_QUERY(Session),
"SEARCH
SESSION: " ++ Session ++ "
END").
-define(GET_PROFILE_COMMAND(Session),
"
    asdfasdfasdfasdf
    GETPROFILE

    SESSION: " ++ Session ++ "

    END
    2563564565asdfa
").

%%------------------------------------------------------------------
%% Responses
%%------------------------------------------------------------------
-define(REG_RESPONSE_SUCCESS, "Registration was successful.").
-define(REG_RESPONSE_BAD_SYNTAX,
"The command [register] could not be interpreted correctly:
Required fields: [\"NICKNAME\",\"PASSWORD\",\"EMAIL\",\"FULLNAME\"]").
-define(LOGIN_RESPONSE_SUCCESS, "Login was successful. Your session is:").
-define(UPD_RESPONSE_SUCCESS,
        "User information was successfully updated.\n").
-define(UPD_RESPONSE_SESSION_ERROR, "Invalid user session. Please log in to continue.\n").
-define(UPD_RESPONSE_BAD_SYNTAX, "The command [update_user] could not be interpreted correctly:
Required fields: [\"SESSION\"]").
-define(CREATE_RESPONSE_SUCCESS, "Game creation was successful. Your game ID is:").
-define(CREATE_RESPONSE_SESSION_ERROR, "Invalid user session. Please log in to continue.\n").
-define(CREATE_RESPONSE_BAD_SYNTAX, "The command [create_game] could not be interpreted correctly:
Required fields: [\"SESSION\",\"GAMENAME\",\"PRESSTYPE\",\"ORDERCIRCLE\",
                  \"RETREATCIRCLE\",\"GAINLOSTCIRCLE\",\"WAITTIME\"]").
-define(RESPONSE_COMMAND_UNKNOWN, "The provided command is unknown.
Supported commands are:").

-define(RECONFIG_RESPONSE_SUCCESS, "Game information was successfully updated.\n").
-define(RECONFIG_RESPONSE_INVALID_DATA,"The game you are trying to reconfigure does not exist.\n").

-define(JOIN_GAME_RESPONSE_SUCCESS,"Join game was successful.\n").
-define(JOIN_GAME_RESPONSE_INVALID_DATA,"You have already joined this game.\n").

-define(GAME_OVERVIEW_RESPONSE_SUCCESS,"Unhandled error.").
-define(GAME_OVERVIEW_RESPONSE_NOT_PLAY, "Only game players can view the gam").

-define(GAME_VIEW_RESPONSE_SUCCESS, "Found 2 games:").
-define(GAME_VIEW_RESPONSE_ERROR, "Invalid user session. Please log in to continue.\n").

-define(GAME_SEARCH_RESPONSE_SUCCESS(GameID), "Found 1 games").
-define(GAME_SEARCH_RESPONSE_ERROR, "[\"Error: Query was empty\"] Please enter some search criteria.").

-define(GAME_ORDER_RESPONSE_SUCCESS, "Game order sent successfully:\n").
-define(GAME_ORDER_RESPONSE_INVALID_INPUT, "Invalid input for the given command.\n").
-define(GAME_ORDER_RESPONSE_INVALID_DATA,"You cannot send orders to a game you are not playing.\n").

-define(SEND_OFF_GAME_MSG_RESPONSE_SUCCESS, "Message was sent. Message ID is: ").
-define(SEND_OFF_GAME_MSG_RESPONSE_FAILED, "Error: The user does not exist.").
-define(SEND_GAME_MSG_RESPONSE_SUCCESS, "Game Message was sent. Game ID is: ").
-define(SEND_GAME_MSG_RESPONSE_NOT_ONGOING, "Error: The game is not active means. the game is not ongoing").

-define(GET_PROFILE_RESPONSE_SUCCESS, "Your Profile:\nNICKNAME:").

%%-------------------------------------------------------------------
%% @doc
%%-------------------------------------------------------------------
basic_fixture_test_ () ->
    {setup,
     fun setup_basic/0,
     fun teardown/1,
     fun echo/1}.

instantiator_fixture_reg_login_test_() ->
    {setup,
     fun setup_reg_login_instantiator/0,
     fun teardown/1,
     fun instantiator/1}.

instantiator_fixture_test_() ->
    {setup,
     fun setup_session_instantiator/0,
     fun teardown/1,
     fun instantiator/1}.

instantiator_two_user_test_() ->
    {setup,
     fun setup_two_user_instantiator/0,
     fun teardown/1,
     fun two_user_instantiator/1}.


%%-------------------------------------------------------------------
%% @doc
%%  Setup to prepare for running tests.
%%
%%  Start exmpp client, make session and do handshaking with
%%  ejabberd server.
%%  You can pass parameter to start_link function to
%%  make session with your user and configure.
%%  For more infomation, see xmpp_client:startlink/3.
%%-------------------------------------------------------------------
setup_basic() ->
    ?debugMsg("Setting up xmpp tests. "),
    Client = basic_test_client,
    xmpp_client:start_link(Client, "password"),
    [[Client]].

setup_reg_login_instantiator() ->
    ?debugMsg("Setting up xmpp tests. "),
    Client = reg_login_test_client,
    xmpp_client:start_link(Client, ?XMPP_PASSWORD),
    Nick = random_nick(),
    [[Client],
     {Client,
      ?REGISTER_COMMAND_CORRECT(Nick),
      ?REG_RESPONSE_SUCCESS,
      "valid registration attempt"},
     {Client,
      "REGISTER fdg END",
      ?REG_RESPONSE_BAD_SYNTAX,
      "register command with missing fields"},
     {Client,
      "register me",
      ?RESPONSE_COMMAND_UNKNOWN,
      "request matching no command"},
     {Client,
      ?LOGIN_COMMAND_CORRECT(Nick),
      ?LOGIN_RESPONSE_SUCCESS,
      "valid login attempt"},
     {Client,
      ?LOGIN_COMMAND_BAD_PASSWORD(Nick),
      "Invalid login data.\n",
      "login request with invalid password"},
     {Client,
      ?LOGIN_COMMAND_BAD_NICK,
      "Invalid login data.\n",
      "login request with invalid nickname"}].

setup_session_instantiator() ->
    Client = session_test_client,
    xmpp_client:start_link(Client, ?XMPP_PASSWORD),
    {Session, _Nick} = login_test_user(Client),
    ?debugVal(Session),
    InvalidSession = "dGVzdA==",

    Game = xmpp_client:xmpp_call(Client, ?SERVICE_BOT,
                               ?CREATE_COMMAND_CORRECT(Session, "white", "1M")),
    ?debugVal(Game),
    {match, [GameID]} = re:run(Game,
                                ?CREATE_RESPONSE_SUCCESS ++ ".*\"(.*)\"",
                                [{capture, all_but_first, list}]),
    ?debugVal(GameID),

    [[Client],
     {Client,
      ?GAME_ORDER_COMMAND(Session, GameID),
       ?GAME_ORDER_RESPONSE_INVALID_DATA,
      "game order invalid data"},
     {Client,
      ?GAME_ORDER_COMMAND_WRONG(Session, GameID),
       ?GAME_ORDER_RESPONSE_INVALID_INPUT,
       "game order invalid input"},

     {Client,
      ?UPDATE_COMMAND_CORRECT(Session),
      ?UPD_RESPONSE_SUCCESS,
      "valid update attempt"},
     {Client,
      ?UPDATE_COMMAND_CORRECT(InvalidSession),
      ?UPD_RESPONSE_SESSION_ERROR,
      "update attempt with invalid session"},
     {Client,
      ?UPDATE_COMMAND_MISSING_FIELD(Session),
      ?UPD_RESPONSE_BAD_SYNTAX,
      "update command with missing fields"},
     {Client,
      ?CREATE_COMMAND_CORRECT(Session, "white", "1M"),
      ?CREATE_RESPONSE_SUCCESS,
      "valid create command"},
     {Client,
      ?CREATE_COMMAND_CORRECT(InvalidSession, "white", "1M"),
      ?CREATE_RESPONSE_SESSION_ERROR,
      "create attempt with invalid session"},
     {Client,
      ?CREATE_COMMAND_MISSING_FIELDS(Session),
      ?CREATE_RESPONSE_BAD_SYNTAX,
      "create command with missing fields"},

     {Client,
      ?RECONFIG_COMMAND(Session, GameID),
      ?RECONFIG_RESPONSE_SUCCESS,
      "successful reconfig game"},
     {Client,
      ?RECONFIG_COMMAND(Session, "1111222"),
      ?RECONFIG_RESPONSE_INVALID_DATA,
      "invalid reconfig game data"},

     {Client,
      ?GAME_OVERVIEW_COMMAND(Session, GameID),
      ?GAME_OVERVIEW_RESPONSE_NOT_PLAY,
      "game overview not play this game"},

     {Client,
      ?JOIN_GAME_COMMAND(Session, GameID, "england"),
      ?JOIN_GAME_RESPONSE_SUCCESS,
      "successful join game"},
     {Client,
      ?JOIN_GAME_COMMAND(Session, GameID, "england"),
      ?JOIN_GAME_RESPONSE_INVALID_DATA,
      "invalid join game data"},
     {Client,
      ?GAME_OVERVIEW_COMMAND(Session, GameID),
      ?GAME_OVERVIEW_RESPONSE_SUCCESS,
      "successful game overview"},

     {Client,
      ?GAME_ORDER_COMMAND(Session, GameID),
      ?GAME_ORDER_RESPONSE_SUCCESS,
      "game order successfully sent"},
     {Client,
      ?SEND_OFF_GAME_MSG(Session, "not_exisiting_user", "a message"),
      ?SEND_OFF_GAME_MSG_RESPONSE_FAILED,
      "game order successfully sent"},

     {Client,
       ?SEND_GAME_MSG(Session, GameID, "france", ?GAME_MSG),
       ?SEND_GAME_MSG_RESPONSE_NOT_ONGOING,
       "send game message to a game which is not started"},

     {Client,
      ?GAME_VIEW_COMMAND(Session),
      ?GAME_VIEW_RESPONSE_SUCCESS,
      "successful game view"},
     {Client,
      ?GAME_VIEW_COMMAND(InvalidSession),
      ?GAME_VIEW_RESPONSE_ERROR,
      "invalid session"},

     {Client,
      ?GAME_SEARCH_COMMAND(Session, GameID),
      ?GAME_SEARCH_RESPONSE_SUCCESS(GameID),
      "successful game search"},
     {Client,
      ?GAME_SEARCH_COMMAND_EMPTY_QUERY(Session),
      ?GAME_SEARCH_RESPONSE_ERROR,
      "query was empty"},

     {Client,
      ?GET_PROFILE_COMMAND(Session),
      ?GET_PROFILE_RESPONSE_SUCCESS,
      "get user profile"}].


setup_two_user_instantiator() ->
    Client1 = user1_test_client,
    xmpp_client:start_link(Client1, ?XMPP_PASSWORD),
    {Session1, Nick1} = login_test_user(Client1),

    Client2 = user2_test_client,
    xmpp_client:start_link(Client2, ?XMPP_PASSWORD),
    {Session2, Nick2} = login_test_user(Client2),

    GameID1 = create_game(Client1, Session1, "white", "1M"),
    GameID2 = create_game(Client1, Session1, "grey", "1M"),

    join_game(Client1, Session1, GameID1, "england"),
    join_game(Client2, Session2, GameID1, "france"),

    join_game(Client1, Session1, GameID2, "england"),
    join_game(Client2, Session2, GameID2, "france"),

    change_game_phase([GameID1, GameID2]),

    Msg = "Hello, this is a message! :)",

    [[Client1, Client2],
     {{Client1,
       ?SEND_OFF_GAME_MSG(Session1, Nick2, Msg),
       ?SEND_OFF_GAME_MSG_RESPONSE_SUCCESS},
      {Client2,
       ".* \(" ++ Nick1 ++ "\):\n\(.*\)\n",
       [[Nick1, Msg]]},
      "successful off game message sending"},
    {{Client1,
       ?SEND_GAME_MSG(Session1, GameID1, "france", ?GAME_MSG),
       ?SEND_GAME_MSG_RESPONSE_SUCCESS},
      {Client2,
       "\s*\(" ++ GameID1 ++ "\)\s*\nCountry.*,\n (.*\)\n",
       [[GameID1, ?GAME_MSG]]},
      "successful game message sending when press type is white"},
     {{Client1,
       ?SEND_GAME_MSG(Session1, GameID2, "france", ?GAME_MSG),
       ?SEND_GAME_MSG_RESPONSE_SUCCESS},
      {Client2,
       "\s*\(" ++ GameID2 ++ "\)\s*\nCountry:unknown.*,\n (.*\)\n",
       [[GameID2, ?GAME_MSG]]},
      "successful game message sending when press type is grey"}
    ].

offline_user_message_test_() ->
    {"deliver off game message to user when get online",
     {setup,
      fun() -> % setup
              ?debugFmt("Testing sending of offline off-game message ~p", [?NOW_UNIV]),
              Client1 = user1_test_client,
              Client2 = user2_test_client,
              Nick1 = random_nick(),
              Nick2 = random_nick(),

              %% create user #2 and log him out:
              xmpp_client:start_link(Client2, ?XMPP_PASSWORD),
              login_test_user (Client2, Nick2),
              xmpp_client:stop (Client2),
              ?debugFmt("offline_message_tst_ Setup 1 done ~p", [?NOW_UNIV]),
              {Client1, Nick1, Client2, Nick2}
      end,
      fun({Client1, Nick1, Client2, Nick2}) -> %instantiator
              fun() ->
                      Msg = "Hello, this is an offline message!",

                      %% create user #1, send an offline message to #2 and log out:
                      xmpp_client:start_link(Client1, ?XMPP_PASSWORD),
                      {Session1, Nick1} = login_test_user (Client1, Nick1),
                      xmpp_client:xmpp_call(Client1,
                                            ?SERVICE_BOT,
                                            ?SEND_OFF_GAME_MSG(Session1, Nick2, Msg)),
                      xmpp_client:stop (Client1),

                      %% wait a bit, log user #2 on and check that `Msg' was received:
                      receive after 1000 -> ok end,
                      xmpp_client:start_link (Client2, ?XMPP_PASSWORD),
                      Response =
                          xmpp_client:xmpp_call(
                            Client2, ?SERVICE_BOT, ?LOGIN_COMMAND_CORRECT(Nick2)),
                      {match, _} = re:run (Response, Msg),
                      ?debugFmt("oflline_message_tst_ 1 done ~p", [?NOW_UNIV])
              end
      end}}.

offline_game_message_test_() ->
    {"deliver in game message to user when get online",
     {setup,
      fun() -> % setup
              ?debugFmt("Testing sending of offline in game message start ~p",
                        [?NOW_UNIV]),
              Client1 = user1_test_client,
              Client2 = user2_test_client,
              Client3 = user3_test_client,
              Nick1 = random_nick(),
              Nick2 = random_nick(),
              Nick3 = random_nick(),

              %%create users and login
              xmpp_client:start_link(Client1, ?XMPP_PASSWORD),
              {Session1, Nick1} = login_test_user (Client1, Nick1),

              xmpp_client:start_link(Client2, ?XMPP_PASSWORD),
              {Session2, Nick2}= login_test_user (Client2, Nick2),

              xmpp_client:start_link(Client3, ?XMPP_PASSWORD),
              {Session3, Nick3}= login_test_user (Client3, Nick3),

              %% create a game to send in game messages
              GameID = create_game(Client1, Session1, "white", "1M"),

              join_game(Client1, Session1, GameID, "england"),
              join_game(Client2, Session2, GameID, "france"),
              join_game(Client3, Session3, GameID, "germany"),

              change_game_phase([GameID]),

              % log out the second and third client
              xmpp_client:stop (Client2),
              xmpp_client:stop (Client3),

              ?debugFmt("offline_message_tst_ 2 setup done ~p", [?NOW_UNIV]),
              {Client1, Nick1, Session1, Client2, Nick2, Client3, Nick3, GameID}
      end,
      fun({Client1, _Nick1, Session1, Client2, Nick2, Client3, Nick3, GameID}) -> %instantiator
              fun() ->
                      Msg = "Hello, this is an offline message!",
                      GMsg= "Hello, this is a game message for two countries",

                      %% one in-game message and one off-game message send to client 2
                      %% one in-gmae message to client 3
                      %% send an offline message to #2
                      ToCountries = "france , germany",
                      xmpp_client:xmpp_call(Client1,
                                            ?SERVICE_BOT,
                                            ?SEND_OFF_GAME_MSG(Session1, Nick2, Msg)),
                      %% send game message to 2 countries (Client2 and client3)
                      xmpp_client:xmpp_call(Client1,
                                            ?SERVICE_BOT,
                                            ?SEND_GAME_MSG(Session1,
                                                           GameID,
                                                           ToCountries,
                                                           GMsg)),
                      xmpp_client:stop (Client1),

                      %% wait a bit, log user #2 on
                      %% and check that `Msg' was received:
                      receive after 1000 -> ok end,
                      xmpp_client:start_link (Client2, ?XMPP_PASSWORD),

                      %% client2 must get one off game message
                      %% and one in game message
                      Response21 =
                          xmpp_client:xmpp_call(
                            Client2, ?SERVICE_BOT, ?LOGIN_COMMAND_CORRECT(Nick2)),
                      {match, _} = re:run (Response21, Msg),

                      Response22 = xmpp_client:get_next_msg(Client2),
                      {match, _} = re:run (Response22, GMsg),

                      %% client3 that will get only one in game message
                      xmpp_client:start_link (Client3, ?XMPP_PASSWORD),
                      Response3 =
                          xmpp_client:xmpp_call(
                            Client2, ?SERVICE_BOT, ?LOGIN_COMMAND_CORRECT(Nick3)),
                      {match, _} = re:run (Response3, GMsg),
                      ?debugFmt("Testing sending of offline in "
                                "and off game message DONE ~p",
                                [?NOW_UNIV])
              end
      end}}.

%%-------------------------------------------------------------------
%% @doc
%%
%%  Clean up environment after runnning tests.
%%
%%  stop exmpp client and close the session
%%-------------------------------------------------------------------
teardown([Clients|_])->
    ?debugMsg("Tearing down xmpp test."),
    % stop spewing output to tty before we kill xmpp_client
    % because it's noisy.
    error_logger:tty(false),
    lists:foreach(fun(Client) ->
                          xmpp_client:stop(Client)
                  end, Clients).


%%-------------------------------------------------------------------
%% instantiate tests
%%-------------------------------------------------------------------
instantiator([_Clients| Tests]) ->
    lists:map(fun({Client, Request, Expect, Description}) ->
                      fun() ->
                              ?debugFmt("Testing ~s.", [Description]),
                              Response = xmpp_client:xmpp_call(
                                           Client, ?SERVICE_BOT, Request),
                              ResponsePrefix = response_prefix(Expect, Response),
                              ?assertEqual(Expect, ResponsePrefix)
                      end
              end, Tests).

%%-------------------------------------------------------------------
%% instantiate two user tests
%%-------------------------------------------------------------------
two_user_instantiator([_Clients| Tests]) ->
    lists:map(
      fun({{Client1, Request1, Expect1},
           {Client2, Regex, Expect2},
           Description}) ->
              fun() ->
                      ?debugFmt("Testing ~s.", [Description]),
                      Response1 = xmpp_client:xmpp_call(
                                    Client1, ?SERVICE_BOT, Request1),
                      ResponsePrefix1 = response_prefix(Expect1,
                                                        Response1),
                      ?assertEqual(Expect1, ResponsePrefix1),
                      timer:sleep (1000),
                      Response2 =
                          xmpp_client:last_received_msg(Client2),
                      {ok, Reg} =
                          re:compile(Regex,
                                     [dotall, {newline, anycrlf}]),
                      Result2 = re:run(Response2, Reg,
                                       [global,
                                        {capture, all_but_first, list},
                                        {newline, anycrlf}]),
                      ?assertEqual({match, Expect2}, Result2)

              end
      end, Tests).

%%-------------------------------------------------------------------
%% @doc
%%  run echo test with ejabberd server. it send a message to a user at
%%  echo local host and get the same message
%%-------------------------------------------------------------------
echo([[Client]]) ->
    [fun() ->
             ok = xmpp_client:clear_last_received(Client),
             RMsg = xmpp_client:xmpp_call(Client, "tester@echo.localhost", ?ECHO_TEST_MSG),
             ?assertEqual(?ECHO_TEST_MSG, RMsg)
     end].


%%------------------------------------------------------------------
%% Internal functions
%%------------------------------------------------------------------

%%------------------------------------------------------------------
%% @doc Return the prefix of the actual value shortened to the length
%% of the expected value.
%%
%% This is for cases where the first part of the response is all that
%% is needed for deciding if things worked as expected, and the rest
%% is variable, e.g. while we pass back an entire user record.
%%
%% Details like whether the details passed to the controller to register
%% were all saved correctly are the responsibility of the controller
%% integration tests.
%%
%% NOTE: This has the risk of making tests pass if you make the expected
%% value the empty string, hence the clause for empty Expected.
%%------------------------------------------------------------------
response_prefix("", _Actual) ->
    "misuse of response_prefix/2";
response_prefix(Expected, Actual) ->
    lists:sublist(Actual, length(Expected)).

random_nick() ->
    "testNick" ++ integer_to_list(random_id()).

random_id() ->
    {{Y,Mo,D},{H,Mi,S}} = erlang:universaltime(),
    {_,_,NowPart} = now(),
    erlang:phash2([Y,Mo,D,H,Mi,S,node(),NowPart]).


%%-------------------------------------------------------------------
%% @doc Creates and logges in a random user und returns the Session id.
%% @end
%%-------------------------------------------------------------------
login_test_user(Client) ->
    login_test_user (Client, undefined).

login_test_user(Client, undefined) ->
    login_test_user (Client, random_nick ());
login_test_user(Client, Nick) ->
    catch xmpp_client:xmpp_call(
      Client, ?SERVICE_BOT, ?REGISTER_COMMAND_CORRECT(Nick)),
    Response =
        xmpp_client:xmpp_call(
          Client, ?SERVICE_BOT, ?LOGIN_COMMAND_CORRECT(Nick)),
    {match, [Session]} = re:run(Response,
                                ?LOGIN_RESPONSE_SUCCESS ++ ".*\"\"(.*)\"\"",
                                [{capture, all_but_first, list}]),
    {Session, Nick}.

join_game(Client, Session,GameID, Country) ->
    Request = ?JOIN_GAME_COMMAND(Session, GameID, Country),
    _Response = xmpp_client:xmpp_call(Client, ?SERVICE_BOT, Request).

create_game(Client, Session, Press, Waittime) ->
    Game = xmpp_client:xmpp_call(Client, ?SERVICE_BOT,
                                 ?CREATE_COMMAND_CORRECT(Session, Press, Waittime)),
    {match, [GameID]} = re:run(Game,
                                ?CREATE_RESPONSE_SUCCESS ++ ".*\"(.*)\"",
                                [{capture, all_but_first, list}]),
    GameID.
%%------------------------------------------------------------------------------
%%    @doc
%%    call this function with list of game ids to change their phase from
%%     waitting to ongoing.
%%    @end
%%------------------------------------------------------------------------------
change_game_phase(GameIDs) ->
    net_kernel:start([test]),
    erlang:set_cookie(node(), 'treacherous_talks'),
    ?debugVal(net_adm:ping('backend@127.0.0.1')),
    lists:foreach(fun(GameID) ->
                          ?debugVal(rpc:call('backend@127.0.0.1',game_timer,
                                             sync_event,
                                             [list_to_integer(GameID), timeout]))
                  end,
                  GameIDs).
