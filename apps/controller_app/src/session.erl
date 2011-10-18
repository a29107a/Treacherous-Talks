%%%-------------------------------------------------------------------
%%% @copyright
%%% COPYRIGHT
%%% @end
%%%-------------------------------------------------------------------
%%% @module session @end
%%%
%%% @doc
%%% Module to handle user and other sessions
%%% @end
%%%
%%% @author Sukumar Yethadka <sbhat7@gmail.com>
%%%
%%% @since : 17 Oct 2011 by Bermuda Triangle
%%% @end
%%%
%%%-------------------------------------------------------------------
-module(session).

-export([add_user/2,
         update_user/3,
         get_user/2,
         is_online/2,
         has_access/3,
         remove_user/2]).

-include_lib("datatypes/include/bucket.hrl").
-include_lib("datatypes/include/user.hrl").

%%------------------------------------------------------------------------------
%% @function add_user/2 @end
%%
%% @doc Adds a user to the session
%%
%% The function adds the user to the session and returns the session id
%%------------------------------------------------------------------------------
add_user(Conn, User) ->
    %% We use the user's id as session id for now
    %% TODO: This is not secure. Change it to a random id
    Id = User#user.id,
    Key = term_to_binary(Id),
    UserObj = db_obj:create(?B_SESSION, Key, User),
    db_c:put(Conn, UserObj),
    Id.


%%------------------------------------------------------------------------------
%% @function update_user/2 @end
%%
%% @doc Updates the user's data in the session
%%------------------------------------------------------------------------------
update_user(Conn, Id, User) ->
    Key = term_to_binary(Id),
    UserObj = db_obj:create(?B_SESSION, Key, User),
    db_c:put(Conn, UserObj),
    ok.


%%------------------------------------------------------------------------------
%% @function get_user/2 @end
%%
%% @doc Returns the user's data from the session
%%------------------------------------------------------------------------------
get_user(Conn, Id) ->
    Key = term_to_binary(Id),
    UserObj = db_c:get(Conn, ?B_SESSION, Key),
    db_obj:get_value(UserObj).


%%------------------------------------------------------------------------------
%% @function is_online/2 @end
%%
%% @doc Checks if the given user has an active session
%%------------------------------------------------------------------------------
is_online(Conn, Id) ->
    case get_user(Conn, Id) of
        {error, notfound} ->
            false;
        {ok, _User} ->
            true
    end.


%%------------------------------------------------------------------------------
%% @function has_access/2 @end
%%
%% @doc Checks if the user has access
%%
%% The function checks if the user has the required role (Role) needed to access
%% the resource
%%------------------------------------------------------------------------------
has_access(Conn, Id, Role) ->
    case get_user(Conn, Id) of
        {error, notfound} ->
            false;
        {ok, User} ->
            check_role(User#user.role, Role)
    end.


%%------------------------------------------------------------------------------
%% @function remove_user/2 @end
%%
%% @doc Removes the user from the session
%%------------------------------------------------------------------------------
remove_user(Conn, Id) ->
    Key = term_to_binary(Id),
    db_c:delete(Conn, ?B_SESSION, Key).


%%------------------------------------------------------------------------------
%% Internal functions
%%------------------------------------------------------------------------------
%% Check if the given Role has enough level to access resource that needs
%% the level of (atleast) RequiredRole
check_role(Role, RequiredRole) ->
    case Role of
        operator ->
            % Operator has full access
            true;
        moderator ->
            if
                (RequiredRole == user) or (RequiredRole == moderator) ->
                    true;
                true ->
                    false
            end;
        user ->
            if
                RequiredRole == user ->
                    true;
                true ->
                    false
            end
    end.