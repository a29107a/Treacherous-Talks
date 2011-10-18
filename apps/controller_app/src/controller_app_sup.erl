-module(controller_app_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

%% Helper macro for declaring children of supervisor
-define(CHILD(I, Type), {I, {I, start_link, []}, permanent, 5000, Type, [I]}).

%% ===================================================================
%% API functions
%% ===================================================================

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, no_arg).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

init(no_arg) ->
    {ok, { {one_for_one, 5, 10},
           [
            ?CHILD(controller_app_worker_sup, supervisor),
            ?CHILD(controller_app_config, worker)
           ]} }.
