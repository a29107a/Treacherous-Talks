%% -----------------------------------------------------------------------------
%% @doc
%% The rules are implemented here, the rule engine merely executes them.
%%
%% Possible Orders:
%% `diplomacy_rules' can process a certain syntax of rules.
%% They  are documented as type specs in this file, go to the "Data Types"
%% section below.
%%
%% `rules:process/4' will return replies that are implemented in this module.
%% depending on the game phase, we have different possibilities.
%% Most important are:
%%
%% <table border="1">
%%   <tr>
%%     <td>`order_phase'</td>
%%     <td>`[{dislodge, unit(), province ()}]'</td>
%%     <td>
%%       the unit needs to be moved in retreat phase or it will be destroyed
%%     </td>
%%   </tr>
%%   <tr>
%%     <td>`count_phase'</td>
%%     <td>`[{has_builds, nation(), integer()}]'</td>
%%     <td>the nation is allowed to build / has to destroy that many units</td>
%%   </tr>
%% </table>
%%
%% look for return values with {reply, Something} if you wonder why stuff is
%% in {@link rules:process/4}'s return list.
%%
%% @end
%% -----------------------------------------------------------------------------
-module (diplomacy_rules).

-export ([create/2,
          do_process/3]).

-include_lib ("eunit/include/eunit.hrl").
-include_lib ("game/include/rule.hrl").

-type nation () :: russia
                   | turkey
                   | austria
                   | italy
                   | germany
                   | france
                   | england.

-type province () :: atom ().
-type unit_type () :: army | fleet.

-type unit () :: {unit_type (), nation ()}.

-type phase () :: order_phase | retreat_phase | count_phase | build_phase.

-type map () :: digraph ().


%% e.g.:
%% {move, {army, austria}, vienna, galicia}
%% {support, {army, austria}, {move, {army, germany}, munich, silesia}}
%% {convoy, {fleet, england}, english_channel, {army, england}, wales, picardy}
-type hold_order () :: {hold, unit ()}.
-type build_order () :: {build, unit (), province ()}.
-type destroy_order () :: {destroy, unit (), province ()}.
-type move_order () :: {move, unit (), From :: province (), To :: province ()}.
-type support_order () :: {support, Fleet :: unit (), Province :: province (),
                           MoveOrHold :: order ()}.
-type convoy_order () :: {convoy,
                          Fleet :: unit (), Where :: province (),
                          Army :: unit (),
                          From :: province (),
                          To :: province ()}.
-type order () :: hold_order () |
                  build_order () |
                  destroy_order () |
                  move_order () |
                  support_order () |
                  convoy_order ().

%% -----------------------------------------------------------------------------
%% @doc
%% creates the rules for a game type.
%% The first parameter decides the game type, the second one the game phase
%% currently, the only supported game type is the atom <pre>standard_game</pre>
%% @end
%% -----------------------------------------------------------------------------
-spec create (GameType, GamePhase) -> [tuple ()] when
      GameType :: standard_game,
      GamePhase :: order_phase | retreat_phase | count_phase | build_phase.
create (standard_game, order_phase) ->
    [unit_exists_rule (),
     convoy_rule (),
     unit_can_go_there_rule (),
     implicit_hold_rule (),
     break_support_rule (),
     support_rule (),
     trade_places_rule (),
     bounce2_rule (),
     hold_vs_move2_rule ()];
create (standard_game, retreat_phase) ->
    [unit_exists_rule (),
     unit_can_go_there_rule (),
     implicit_hold_rule (),
     trade_places_rule (),
     bounce2_rule (),
     hold_vs_move2_rule (),
     remove_undislodged_units_rule (),
     remove_dislodge_state_rule ()];
create (standard_game, count_phase) ->
    [no_orders_accepted_rule (),
     count_units_rule ()
     ];
create (standard_game, build_phase) ->
    [unit_can_build_there_rule (),
     can_build_rule (),
     civil_disorder_rule ()].

-spec do_process (phase (), map (), order ()) -> any ().
do_process (_, Map, {move, Unit, From, To}) ->
%    ?debugMsg (io_lib:format ("processing ~p~n", [Order])),
    map:move_unit (Map, Unit, From, To),
    [];
do_process (_, _Map, {hold, _, _}) ->
    [];
do_process (build_phase, Map, {build, Unit = {_Type, _Nation}, Where}) ->
    map:add_unit (Map, Unit, Where),
    [];
do_process (_, Map, {destroy, Unit, From}) ->
%    ?debugMsg (io_lib:format ("destroying ~p, ~p", [Unit, From])),
    map:remove_unit (Map, Unit, From),
    [];
do_process (_, _, {support, _, _, _}) ->
    [];
do_process (_, _, {convoy, _, _, _, _, _}) ->
    [];
do_process (build_phase, Map, {destroy_furthest_units, Nation, ToDestroy}) ->
%    io:format (user, "destroy_furthest_unit, ~p~n", [Nation]),
    Units = map:get_units (Map),
    FilteredUnits = lists:filter (fun ({_Province, {_, Owner}}) ->
                          Owner == Nation
                  end,
                  Units),
    TaggedUnits =
        ordsets:from_list (
          lists:map (fun ({Province, Unit}) ->
                             MinDist =
                                 lists:foldl (
                                   fun (HomeProvince, Acc) ->
                                           Dist = map:get_distance (Map,
                                                                    Province,
                                                                    HomeProvince),
                                           case Acc of
                                               infinity ->
                                                   Dist;
                                               _Other ->
                                                   lists:min ([Acc, Dist])
                                           end
                                   end,
                                   infinity,
                                   get_home_provinces (Map, Nation)),
                             {MinDist, Province, Unit}
                     end,
                     FilteredUnits)),
    {_, FurthestUnits} =
        lists:split (length (TaggedUnits) - ToDestroy, TaggedUnits),
    lists:foreach (fun ({_, TargetProv, TargetUnit}) ->
                           do_process (build_phase,
                                       Map,
                                       {destroy, TargetUnit, TargetProv})
                   end,
                  FurthestUnits),
    [];
do_process (Phase, _Map, Order) ->
    erlang:error ({error,
                   {unhandled_case, ?MODULE, ?LINE, [Phase, 'Map', Order]}}).

%% remove orders for non-existing units
unit_exists_rule () ->
    #rule{name = unit_exists,
          arity = 1,
          detector = fun unit_does_not_exist/2,
          actor = fun delete_orders_actor/2}.

%% remove build-orders that are not supply centers with a matching
%% original_owner attribute
unit_can_build_there_rule () ->
    #rule{name = unit_can_build_there,
          arity = 1,
          detector = fun unit_can_build_there_detector/2,
          actor = fun unit_can_build_there_actor/2}.

%% enable convoys across one fleet
convoy_rule () ->
    #rule{name = convoy,
          arity = 2,
          detector = fun simple_convoy_detector/2,
          actor = fun simple_convoy_actor/2}.

no_orders_accepted_rule () ->
    #rule{name = no_orders_accepted,
          arity = 1,
          actor = fun delete_orders_actor/2}.

count_units_rule () ->
    #rule{name = count_units,
          arity = 0,
          actor = fun count_units_set_owner_actor/2}.

can_build_rule () ->
    #rule {name = can_build,
           arity = 1,
           detector = fun can_build_detector/2,
           actor = fun can_build_actor/2}.

can_build_detector (Map, {{build, {_Type, Nation}, _Somewhere}}) ->
    {ok, License} = dict:find (Nation, get_build_licenses (Map)),
    License =< 0;
can_build_detector (_, _) ->
    false.

can_build_actor (Map, {BuildOrder}) ->
    [{reply, {no_builds_left, BuildOrder}} |
      delete_orders_actor (Map, {BuildOrder})].

civil_disorder_rule () ->
    #rule {name = civil_disorder,
           arity = all_orders,
           actor = fun civil_disorder_actor/2}.

civil_disorder_actor (Map, Orders) ->
    CorrectedLicenses =
        lists:foldl (fun (Order, Acc) ->
                             case Order of
                                 {build, {_, Nation}, _Province} ->
                                     %% DANGER, Val not changed
%                                     erlang:error ({error, 'VAL'}),
                                     {ok, Val} = dict:find (Nation, Acc),
                                     dict:store (Nation, Val, Acc);
%                                 {destroy_furthest_unit, Nation} ->
%                                     {ok, Val} = dict:find (Nation, Acc),
%                                     dict:store (Nation, Val + 1, Acc);
                                 {destroy, {_, Nation}, _Province} ->
                                     {ok, Val} = dict:find (Nation, Acc),
                                     dict:store (Nation, Val + 1, Acc);
                                 _ -> Acc
                             end
                     end,
                     get_build_licenses (Map),
                     Orders),
    NeedToDestroy =
        lists:filter (
          fun ({_Nation, Counter}) ->
                  Counter < 0
          end,
          dict:to_list (CorrectedLicenses)),
    %% now emit the destroy-furthest-units orders:
    lists:map (fun ({Nation, Counter}) ->
                       {add,
                        {destroy_furthest_units,
                         Nation, -Counter}}
               end,
               NeedToDestroy).

%% remove units that where not dislodged yet
remove_undislodged_units_rule () ->
    #rule{name = remove_undislodged_units,
          arity = 0,
          actor = fun remove_undislodged_units_actor/2}.

%% go through all units and check if there is an order for them. if not: add a
%% hold order
implicit_hold_rule () ->
    #rule{name = implicit_hold_rule,
          arity = all_orders,
          actor = fun implicit_hold_rule_actor/2}.

%% removes the 'dislodge' k/v pair from the unit dicts in
%% case it contains 'true'
remove_dislodge_state_rule () ->
    #rule{name = remove_retreat_state,
          arity = 1,
          detector = fun (Map, {Order}) ->
                             Unit = get_first_unit (Order),
                             Where = get_first_from (Order),
                             map:get_unit_info (Map, Unit, Where, false)
                     end,
          actor = fun (Map, {Order}) ->
                          Unit = get_first_unit (Order),
                          Where = get_first_from (Order),
                          map:remove_unit_info (Map, Unit, Where, dislodge)
                  end}.

%% units can not exchange places without a convoy
trade_places_rule () ->
    #rule{name = trade_places,
          arity = 2,
          detector = fun trade_places_detector/2,
          actor = fun trade_places_actor/2}.

%% remove orders where units can not move to the target province
unit_can_go_there_rule () ->
    #rule{name = unit_can_go_there,
          arity = 1,
          detector = fun unit_can_go_there_detector/2,
          actor = fun replace_by_hold_actor/2}.

%% remove orders where two equally strong units want to enter the same province
bounce2_rule () ->
    #rule{name = bounce2,
          arity = 2,
          detector = fun bounce2_detector/2,
          actor = fun bounce2_actor/2}.

%% remove orders, where a unit wants to move into an occupied province
hold_vs_move2_rule () ->
    #rule{name = hold_vs_move2,
          arity = 2,
          detector = fun hold_vs_move2_detector/2,
          actor = fun hold_vs_move2_actor/2}.

%% remove support orders when they are broken by a move:
break_support_rule () ->
    #rule{name = break_support,
          arity = 2,
          detector = fun break_support_detector/2,
          actor = fun break_support_actor/2}.

%% add support order to the supported unit's dict
support_rule () ->
    #rule{name = support,
          arity = 2,
          detector = fun support_detector/2,
          actor = fun support_actor/2}.

%% -----------------------------------------------------------------------------
%% Implementation
%% -----------------------------------------------------------------------------

%% count the units in a map, count the owners of centers in a map and
%% reply how much they have to build/remove
count_units_set_owner_actor (Map, {}) ->
    % the difference is the number of builds the nation is entitled to:
    lists:map (fun ({Nation, Builds}) ->
                       {reply, {has_builds, Nation, Builds}}
               end,
               dict:to_list (get_build_licenses (Map))).

implicit_hold_rule_actor (Map, Orders) when is_list (Orders) ->
    UnitsWoOrders =
        lists:foldl (
          fun (Order, Units) ->
                  lists:delete ({get_first_from (Order),
                                 get_first_unit (Order)}, Units)
          end,
          map:get_units (Map),
          Orders),
    lists:foldl (fun ({Province, Unit}, ReplyAcc) ->
                         [{add, {hold, Unit, Province}},
                          {reply, {added, {hold, Unit, Province}}} | ReplyAcc]
                 end,
                 [],
                 UnitsWoOrders);
implicit_hold_rule_actor (_Map, Orders) ->
    erlang:error ({error, unhandled, Orders}).

simple_convoy_detector (_Map, {{convoy, _, _, _, _, _},
                               {move, _, _, _}}) ->
    true;
simple_convoy_detector (Map, {M = {move, _, _, _},
                              C = {convoy, _, _, _, _, _}}) ->
    simple_convoy_detector (Map, {C, M});
simple_convoy_detector (_, _Other) ->
    false.

simple_convoy_actor (Map, {{move, _, _, _},
                           C = {convoy, _, _, _, _, _}}) ->
%    map:is_reachable (Map, From, Where, fleet) and
%        map:is_reachable (Map, Where, To, fleet),
    do_add_convoy (Map, C),
    [].

remove_undislodged_units_actor (Map, {}) ->
    AllUnits = map:get_units (Map),
    lists:foreach (
      fun ({Province, Unit}) ->
              case
                  map:get_unit_info (Map,
                                     Unit,
                                     Province,
                                     dislodge, false) of
                  true ->
                      map:remove_unit (Map,
                                       Unit,
                                       Province);
                  _ ->
                      ok
              end
      end,
      AllUnits),
      [].

break_support_detector (Map, {{move, {UType, _Nation}, From, SupPlace},
                              {support, _Unit2, SupPlace, _Order}}) ->
    map:is_reachable (Map, From, SupPlace, UType);
break_support_detector (Map, {S = {support, _, _, _}, M = {move, _, _, _}}) ->
    break_support_detector (Map, {M, S});
break_support_detector (_Map, _) ->
    false.

break_support_actor (Map, {{move, {_Type, _Nation}, _From, SupPlace},
                           S = {support, _Unit2, SupPlace, _Order}}) ->
    do_remove_support (Map, S),
    replace_by_hold_actor (Map, {S}).

support_detector (_Map, {_Order, {support, _Unit, _Where, _Order}}) ->
    true;
support_detector (_Map, {{support, _Unit, _Where, _Order}, _Order}) ->
    true;
support_detector (_Map, _Orders = {_, _}) ->
    false.

get_first_unit ({move, Unit, _, _}) ->
    Unit;
get_first_unit ({hold, Unit, _}) ->
    Unit;
get_first_unit ({support, Unit, _Where, _Order}) ->
    Unit;
get_first_unit ({convoy, Fleet, _Where, _Unit, _From, _To}) ->
    Fleet.

get_first_from ({move, _, From, _}) ->
    From;
get_first_from ({hold, _, Where}) ->
    Where;
get_first_from ({support, _Unit, Where, _Order}) ->
    Where;
get_first_from ({convoy, _Fleet, Where, _Unit, _From, _To}) ->
    Where.

%% gets the 'moving' unit, this also means a unit that holds.
%% the distinction is important for support- and convoy-orders
get_moving_unit ({move, Unit, _, _}) ->
    Unit;
get_moving_unit ({hold, Unit, _}) ->
    Unit;
get_moving_unit ({support, _Unit, Order}) ->
    get_moving_unit (Order);
get_moving_unit ({convoy, _Fleet, _Where, Unit, _From, _To}) ->
    Unit.

get_moving_from ({move, _, From, _}) ->
    From;
get_moving_from ({hold, _, Where}) ->
    Where.

get_moving_to ({move, _, _, To}) ->
    To;
get_moving_to ({hold, _, Where}) ->
    Where.

is_supportable ({move, _, _, _}) ->
    true;
is_supportable ({hold, _, _}) ->
    true;
is_supportable (_) ->
    false.

%% return a dict, that contains nation()/integer() pairs,
%% denoting the numbers of builds (if integer is positive) a nation has
%% or the number of units it must destroy (if integer is negative)
get_build_licenses (Map) ->
    % count how many units each nation has and set province owners
    Dict =
        lists:foldl (
          fun ({Province, {_Type, Nation}}, Dict) ->
                  map:set_province_info (Map, Province, owner, Nation),
                  OldCnt = case dict:find (Nation, Dict) of
                               {ok, Count} ->
                                   Count;
                               error ->
                                   0
                           end,
                  dict:store (Nation, OldCnt - 1, Dict)
          end,
          dict:new (),
          map:get_units (Map)),
    Centers = lists:filter (fun (Province) ->
                                    map:get_province_info (Map,
                                                           Province,
                                                           center) == true
                            end,
                           map:get_provinces (Map)),
    Owners = lists:map (fun (Center) ->
                                map:get_province_info (Map, Center, owner)
                        end,
                        Centers),
    % now add the number of centers each nation holds:
    lists:foldl (
      fun (Owner, DictAcc) ->
              case Owner of
                  undefined -> DictAcc;
                  Owner ->
                      OldCnt = case dict:find (Owner, DictAcc) of
                                   error -> 0;
                                   {ok, Value} -> Value
                               end,
                      dict:store (Owner, OldCnt + 1, DictAcc)
              end
      end,
      Dict,
      Owners).

%% todo: this is the simple implementation that covers no chains of convoys:
is_covered_by_convoy (Map, {move, Army, From, To}) ->
    ConvoyOrders = map:get_unit_info (Map, Army, From, convoys, []),
    lists:any (fun ({convoy, _Fleet, _Where, CArmy, CFrom, CTo}) ->
                       (Army == CArmy) and
                                         (From == CFrom) and
                                                           (To == CTo)
               end,
               ConvoyOrders).

%% adds the convoy order to the Army's convoy attribute
do_add_convoy (Map, ConvoyOrder = {convoy, _Fleet, _Where, Army, From, _To}) ->
    ConvoyOrders = map:get_unit_info (Map, Army, From, convoys, []),
    case lists:member (ConvoyOrder, ConvoyOrders) of
        true ->
            ok;
        false ->
            map:set_unit_info (Map, Army, From,
                               convoys, [ConvoyOrder | ConvoyOrders])
    end.

do_remove_support (Map, SupportOrder = {support, _, _, SupportedOrder}) ->
    SupportedUnit = get_moving_unit (SupportedOrder),
    SupportedWhere = get_moving_from (SupportedOrder),
    SupportingOrders =
        map:get_unit_info (Map,
                           SupportedUnit, SupportedWhere, support_orders, []),
    map:set_unit_info (Map, SupportedUnit, SupportedWhere,
                       support_orders,
                       lists:delete (SupportOrder, SupportingOrders)).

do_add_support (Map, SupportOrder = {support, _, _, SupportedOrder}) ->
    SupportedUnit = get_moving_unit (SupportedOrder),
    SupportedWhere = get_moving_from (SupportedOrder),
    SupportingOrders =
        map:get_unit_info (Map,
                           SupportedUnit, SupportedWhere, support_orders, []),
    case lists:member (SupportOrder, SupportingOrders) of
        true ->
            ok;
        false ->
            map:set_unit_info (Map, SupportedUnit, SupportedWhere,
                               support_orders,
                               [SupportOrder | SupportingOrders])
    end.

support_actor (Map, {OtherOrder, SupOrder = {support, _, _, _}}) ->
    support_actor (Map, {SupOrder, OtherOrder});
support_actor (Map,
               {SupOrder = {support, {SupType, _}, SupPlace, _Order},
                OtherOrder}) ->
    case (is_supportable (OtherOrder)) of
        true ->
            To = get_moving_to (OtherOrder),
            case map:is_reachable (Map, SupPlace, To, SupType) of
                true ->
                    do_add_support (Map, SupOrder),
                    [];
                false ->
                    [{remove, SupOrder}]
            end;
        false ->
            [{remove, SupOrder}]
    end.

hold_vs_move2_detector (_Map, {{move, _Unit1, _From1, To},
                               {hold, _Unit2, To}}) ->
    true;
hold_vs_move2_detector (_Map, {{hold, _Unit1, To},
                               {move, _Unit2, _From1, To}}) ->
    true;
hold_vs_move2_detector (_Map, _) ->
    false.

hold_vs_move2_actor (Map, {HoldOrder = {hold, HoldUnit, HoldPlace},
                           MoveOrder = {move, _MoveUnit, _From, _HoldPlace}}) ->
    HoldStrength = get_unit_strength (Map, HoldOrder),
    MoveStrength = get_unit_strength (Map, MoveOrder),
    if
        HoldStrength >= MoveStrength ->
            replace_by_hold_actor (Map, {MoveOrder});
        true ->
            map:set_unit_info (Map, HoldUnit, HoldPlace, dislodge, true),
            [{remove, HoldOrder}, {reply, {dislodge, HoldUnit, HoldPlace}}]
    end.

bounce2_detector (_Map, {{move, _Unit1, _From1, _To},
                         {move, _Unit2, _From2, _To}}) ->
    true;
bounce2_detector (_Map, {_, _}) ->
    false.

get_unit_strength (Map, Order) ->
    %% supports are valid for a specific move only - we are counting them here:
    lists:foldl (
      fun (SupOrder, Sum) ->
              case SupOrder of
                  {support, _U, _W, Order} ->
                      Sum+1;
                  _ ->
                      Sum
              end
      end,
      1,
      map:get_unit_info (Map,
                         get_moving_unit (Order),
                         get_first_from (Order),
                         support_orders, [])).

bounce2_actor (Map,
               {O1 = {move, _, _, To},
                O2 = {move, _, _, To}}) ->
    Strength1 = get_unit_strength (Map, O1),
    Strength2 = get_unit_strength (Map, O2),
    if
        Strength1 > Strength2 ->
            replace_by_hold_actor (Map, {O2});
        Strength2 > Strength1 ->
            replace_by_hold_actor (Map, {O1});
        true ->
            replace_by_hold_actor (Map, {O1, O2})
    end.

unit_can_build_there_detector (Map,
                               {{build, {_Type, Nation}, Province}}) ->
    case map:get_province_info (Map, Province, original_owner) of
        Nation ->
            false;
        _ ->
            case map:get_units (Map, Province) of
                [] ->
                    false;
                _ ->
                    true
            end
    end;
unit_can_build_there_detector (_, _) ->
    false.

unit_can_build_there_actor (_Map, Build) ->
    [{remove, Build}].

unit_can_go_there_detector (Map, {M = {move, {Type, _Owner}, From, To}}) ->
    not lists:member (To,
                      map:get_reachable (Map, From, Type)) and
        not is_covered_by_convoy (Map, M);
unit_can_go_there_detector (_Map, _) ->
    false.

unit_does_not_exist (Map, {Order}) ->
    not map:unit_exists (Map, get_first_from (Order), get_first_unit (Order)).

trade_places_detector (_Map, {{move, _Unit1, From, To},
                              {move, _Unit2, To, From}}) ->
    true;
trade_places_detector (_Map, _Other) ->
    false.

trade_places_actor (Map, {M1, M2}) ->
    S1 = get_unit_strength (Map, M1),
    S2 = get_unit_strength (Map, M2),
    if
        S1 > S2 ->
            [{remove, M2},
             {reply, {dislodge, get_moving_unit (M2), get_moving_from (M2)}}];
        S2 > S1 ->
            [{remove, M1},
             {reply, {dislodge, get_moving_unit (M1), get_moving_from (M1)}}];
        true ->
            replace_by_hold_actor (Map, {M1, M2})
    end.

delete_orders_actor (_Map, {A}) ->
    [{remove, A}];
delete_orders_actor (_Map, {A,B}) ->
    [{remove, A}, {remove, B}];
delete_orders_actor (_Map, {A,B,C}) ->
    [{remove, A}, {remove, B}, {remove, C}].

replace_by_hold_actor (_Map, {A}) ->
    [{remove, A},
     {add, {hold, get_first_unit (A), get_first_from (A)}}];
replace_by_hold_actor (_Map, {A,B}) ->
    [{remove, A}, {remove, B},
     {add, {hold, get_first_unit (A), get_first_from (A)}},
     {add, {hold, get_first_unit (B), get_first_from (B)}}];
replace_by_hold_actor (_Map, {A,B,C}) ->
    [{remove, A}, {remove, B}, {remove, C},
     {add, {hold, get_first_unit (A), get_first_from (A)}},
     {add, {hold, get_first_unit (B), get_first_from (B)}},
     {add, {hold, get_first_unit (C), get_first_from (C)}}].

get_home_provinces (Map, Nation) ->
    ordsets:from_list (
      lists:filter (fun (Province) ->
                            Nation == map:get_province_info (Map, Province,
                                                             original_owner)
                    end,
                    map:get_provinces (Map))).

get_home_provinces_test () ->
    Map = map_data:create (standard_game),
    ?assertEqual ([bohemia, budapest, galicia, trieste, tyrolia, vienna],
                  get_home_provinces (Map, austria)),
    map_data:delete (Map).
