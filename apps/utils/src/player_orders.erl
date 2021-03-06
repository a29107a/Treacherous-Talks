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
%%% @doc player_orders
%%%
%%% A module for recognizing play move orders in email body
%%%
%%% @TODO modify the code in a concurrent a way, so that results of some expensive initiations can be stored in other processes.
%%% @TODO use proper specs
%%% @end
%%%
%%%-------------------------------------------------------------------
-module(player_orders).

%% Exports for API
-export([parse_orders/1]).

%% Exports for eunit
-export([translate_location/1,interpret_str_orders/1,
         translate_abbv_to_fullname_atom/1,interpret_order_line/1]).

-include("test_utils.hrl").
-include("player_orders.hrl").
-include("command_parser.hrl").

%%------------------------------------------------------------------------------
%% @TODO input example is incomplete
%% @doc parse player's orders to a list of order terms.
%%  Return {ok, {OrderList, ErrorList}}
%%
%%  Example:
%%  Input:  "F boh -> nwy         \n
%%           A vie H              \n
%%           A mun S A bor -> swe "
%%
%%  Output: {ok, {[#move{...},
%%                 #hold{...},
%%                 #support_move{...}],
%%                [{error, ...},
%%                 {error, ...}]}}
%%
%%  Valid Order Example: (case insensitive)
%%
%% ----the following unit types are equivalent----------------
%%     A = Army
%%     F = Fleet
%%     A Lon->Nrg = Army Lon->Nrg
%%
%% ----the following move orders are equivalent----------------
%%     A Lon->Nrg
%%     A Lon-Nrg
%%     A Lon m Nrg
%%     A Lon move Nrg
%%
%% ---the following convoy orders are equivalent-----------------
%%     F Nth C A Lon-Nrg
%%     F Nth Convoy A Lon-Nrg
%%
%% ---the following hold orders are equivalent-----------------
%%     A Bre H
%%     A Bre Hold
%%
%% ---the following support orders are equivalent-----------------
%%     F Fin S Bre
%%     F Fin Support Bre
%%
%% ---the following remove orders are equivalent-----------------
%%     Disband A mun
%%     D A mun
%%
%% ---the following build orders are equivalent-----------------
%%     Build A mun
%%     B A mun
%%
%% @end
%%------------------------------------------------------------------------------
parse_orders (EmailBody) when is_binary(EmailBody) ->
    parse_orders (binary_to_list(EmailBody));
parse_orders ([]) -> {error, "empty order"};
parse_orders (EmailBody) ->
    CutTailBlank = string:strip(EmailBody, right),
    MailLines = string:tokens(CutTailBlank, "\n,"),

    % error will be throw out from get_field_value/2
    catch begin
          [RawSessionId|RestLines] = MailLines,
          SessionId = get_field_value(RawSessionId, ?SESSION":\s*(.*)\s*"),

          [RawGameId|RawOrderList] = RestLines,
          GameIdStr = get_field_value(RawGameId, ?GAMEID":\s*([0-9]*)\s*"),
          GameId = list_to_integer(GameIdStr),

          OrderList = interpret_str_orders(RawOrderList),
          ResultOrders = lists:partition(fun(X)->
                                        element(1, X) /= error end, OrderList),
          % ResultOrders = {[order], [error]}
          case ResultOrders of
              {GameOrderList, []} ->
                  {ok, SessionId, {GameId, GameOrderList}};
              {_, Error} ->
                  {error,{invalid_input, Error}}
          end
    end.

% this function should be only used by parse_orders/1
get_field_value(Data, Pattern) ->
    Match = re:run(Data, Pattern,
                        [{capture, all_but_first, list},{newline, anycrlf}]),
    case Match of
        {match, [Value]} -> Value;
        nomatch -> throw({error, Data ++ "#invalid value#" ++ Pattern})
    end.


%%------------------------------------------------------------------------------
%% @doc interpret each mail line to erlang terms
%%  Example:
%%  Input :["F boh -> nwy         \r",
%%          "A vie H              ",
%%          "A mun S A bor -> swe "]
%%
%%  Output: [#move{...},
%%           #hold{...},
%%           #support_move{...}]
%% @end
%%------------------------------------------------------------------------------
interpret_str_orders (MailLines) ->
    {ok, OrderParser} = re:compile(?ORD_PARSER, [caseless, {newline, anycrlf}]),
    interpret_str_orders(MailLines, OrderParser, []).

interpret_str_orders ([], _, StrOrderList) -> StrOrderList;
interpret_str_orders ([CurrentLine|Rest], OrderParser, StrOrderList) ->
    ExtractResult = re:run(CurrentLine, OrderParser, ?ORD_PARSER_SETTING),
    case ExtractResult of
        {match, ExtractedStrOrderLine} ->
            InterpretedLine = (catch interpret_order_line(ExtractedStrOrderLine)),
            case InterpretedLine of
                {'EXIT', _} ->
                    interpret_str_orders (Rest, OrderParser, StrOrderList);
                _ ->
                    interpret_str_orders (Rest, OrderParser, [InterpretedLine|StrOrderList])
            end;
        nomatch ->
            % catch every error line
            interpret_str_orders (Rest, OrderParser, [{error, CurrentLine ++
                                            "#bad order format"}|StrOrderList])
    end.

%%------------------------------------------------------------------------------
%% @doc interpret a single player order string line to erlang terms
%%  Example:
%%  Input :"F boh -> nwy         \r"
%%
%%  Output: #move{subj_unit=fleet, subj_loc=boh, subj_dst=nwy}
%% @end
%%------------------------------------------------------------------------------
interpret_order_line (OrderLine) ->
    [SubjUnitStr, SubjLocStr, SubjActStr, ObjUnitStr, ObjSrcStr, ObjDstStr,
     CoastStr] = OrderLine,
    SubjAct = translate_action(SubjActStr),
    SubjUnit = translate_unit(SubjUnitStr),
    SubjLoc = translate_location(SubjLocStr),
    ObjUnit = translate_unit(ObjUnitStr),
    ObjSrc = translate_location(ObjSrcStr),
    ObjDst = translate_location(ObjDstStr),
    Coast = translate_coast(CoastStr),

    case SubjAct of
        move when SubjLoc /=nil, ObjSrc/=nil, SubjUnit/=nil->
            #move{subj_unit = SubjUnit, subj_src_loc = SubjLoc,
                  subj_dst_loc = ObjSrc, coast = Coast};
        support when ObjDst == nil, SubjLoc /=nil, ObjSrc /=nil,
                     SubjUnit/=nil, ObjUnit/=nil ->
            #support_hold{subj_unit = SubjUnit, subj_loc = SubjLoc,
                          obj_unit = ObjUnit, obj_loc = ObjSrc};
        support when SubjLoc /=nil, ObjSrc /=nil, ObjDst /=nil,
                     SubjUnit/=nil, ObjUnit/=nil->
            #support_move{subj_unit = SubjUnit, subj_loc = SubjLoc,
                          obj_unit = ObjUnit, obj_src_loc = ObjSrc,
                          obj_dst_loc = ObjDst, coast = Coast};
        hold when SubjLoc /=nil, SubjUnit/=nil->
            #hold{subj_unit = SubjUnit, subj_loc = SubjLoc};
        convoy when SubjLoc /=nil, ObjSrc /=nil, ObjDst /=nil,
                    SubjUnit/=nil, ObjUnit/=nil ->
            #convoy{subj_unit = SubjUnit,
                    subj_loc = SubjLoc,
                    obj_unit = ObjUnit,
                    obj_src_loc = ObjSrc, obj_dst_loc = ObjDst};
        build when ObjUnit /=nil, ObjSrc /=nil, ObjUnit/=nil ->
            #build{obj_unit = ObjUnit, obj_loc = ObjSrc, coast = Coast};
        disband when ObjSrc /= nil, ObjUnit/=nil ->
            #disband{obj_unit = ObjUnit, obj_loc = ObjSrc};
        _ ->
            throw({error, {"invalid action#",OrderLine}})
    end.

% functions prefix with translate_
% should only be called by interpret_order_line/1----------------------------
translate_location([]) -> nil;
translate_location(Loc) when length(Loc) == 3 ->
    translate_abbv_to_fullname_atom(Loc);
translate_location(Loc) ->
    LowercasedLoc = string:to_lower(Loc),
    ExistingAtom = (catch list_to_existing_atom(LowercasedLoc)),
    case ExistingAtom of
        {'EXIT', _} ->
            throw({error, Loc ++ "#invalid location name, not in atom table"});
        MatchedAtom ->
            case (catch dict:fetch(MatchedAtom, ?LOC_DICT)) of
                true ->
                    MatchedAtom;
                _ ->
                    throw({error, Loc ++ "#invalid location name, not in location list"})
            end
    end.


translate_coast(Key) ->
    get_translation(Key, ?TRANS_COAST, "coast name").


translate_unit(Key) ->
    get_translation(Key, ?TRANS_UNIT, "unit name").


translate_action(Key) ->
    NewKey = string:strip(Key),
    get_translation(NewKey, ?TRANS_ACTION, "action name").


translate_abbv_to_fullname_atom(Key) ->
    get_translation(Key, ?TRANS_LOC_ABBV, "loc abbv").


get_translation(Key, PropList, ErrorMsg) ->
    LowercasedKey = string:to_lower(Key),
    Value = proplists:get_value(LowercasedKey, PropList),
    case Value of
        undefined ->
            throw({error, Key ++ "#invalid " ++ ErrorMsg});
        _ ->
            Value
    end.
