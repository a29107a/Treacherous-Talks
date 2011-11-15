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
-module (map_data).

-export ([create/1,
          delete/1]).

-type map () :: digraph ().

%% -----------------------------------------------------------------------------
%% @doc
%% create a new map with all countries and units and stuff.
%% receives the game mode as parameter, currently, it only supports
%% standard_game and empty
%% -----------------------------------------------------------------------------
-spec create (GameType) -> Map when
      GameType :: empty | standard_game,
      Map :: map ().
create (empty) ->
    digraph:new ([cyclic, protected]);
create (standard_game) ->
    Map = create (empty),
                                                % initialize provinces:
    [map:add_province (Map, Prov) || Prov <- [% Austria:
                                                    bohemia,
                                                    budapest,
                                                    galicia,
                                                    trieste,
                                                    tyrolia,
                                                    vienna,
                                                % England:
                                                    clyde,
                                                    edinburgh,
                                                    liverpool,
                                                    london,
                                                    wales,
                                                    yorkshire,
                                                % France:
                                                    brest,
                                                    burgundy,
                                                    gascony,
                                                    marseilles,
                                                    paris,
                                                    picardy,
                                                % Germany:
                                                    berlin,
                                                    kiel,
                                                    munich,
                                                    prussia,
                                                    ruhr,
                                                    silesia,
                                                % Italy:
                                                    apulia,
                                                    naples,
                                                    piedmont,
                                                    rome,
                                                    tuscany,
                                                    venice,
                                                % Russia:
                                                    finland,
                                                    livonia,
                                                    moscow,
                                                    sevastopol,
                                                    st_petersburg,
                                                    ukraine,
                                                    warsaw,
                                                % Turkey:
                                                    ankara,
                                                    armenia,
                                                    constantinople,
                                                    smyrna,
                                                    syria,
                                                % Neutrals:
                                                    albania,
                                                    belgium,
                                                    bulgaria,
                                                    denmark,
                                                    greece,
                                                    holland,
                                                    norway,
                                                    north_africa,
                                                    portugal,
                                                    rumania,
                                                    serbia,
                                                    spain,
                                                    sweden,
                                                    tunis,
                                                % Bodies of Water
                                                    adriatic_sea,
                                                    aegean_sea,
                                                    baltic_sea,
                                                    barents_sea,
                                                    black_sea,
                                                    eastern_mediterranean,
                                                    english_channel,
                                                    gulf_of_bothnia,
                                                    gulf_of_lyon,
                                                    helgoland_bight,
                                                    ionian_sea,
                                                    irish_sea,
                                                    mid_atlantic_ocean,
                                                    north_atlantic_ocean,
                                                    north_sea,
                                                    norwegian_sea,
                                                    skagerrak,
                                                    tyrrhenian_sea,
                                                    western_mediterranean]],
                                                % connect neighbouring provinces:
    [map:connect_provinces (Map, A, B, Types) ||
        {A, B, Types} <- [
                          {bohemia, galicia, [army]},
                          {bohemia, vienna, [army]},
                          {bohemia, tyrolia, [army]},
                          {bohemia, silesia, [army]},
                          {bohemia, munich, [army]},
                          {budapest, rumania, [army]},
                          {budapest, serbia, [army]},
                          {galicia, warsaw, [army]},
                          {galicia, ukraine, [army]},
                          {galicia, rumania, [army]},
                          {galicia, budapest, [army]},
                          {galicia, silesia, [army]},
                          {trieste, venice, [army, fleet]},
                          {trieste, budapest, [army]},
                          {trieste, serbia, [army]},
                          {trieste, albania, [army, fleet]},
                          {trieste, adriatic_sea, [fleet]},
                          {tyrolia, trieste, [army]},
                          {tyrolia, vienna, [army]},
                          {tyrolia, munich, [army]},
                          {tyrolia, venice, [army]},
                          {tyrolia, piedmont, [army]},
                          {vienna, trieste, [army]},
                          {vienna, budapest, [army]},
                          {vienna, galicia, [army]},
                          {clyde, edinburgh, [army, fleet]},
                          {clyde, liverpool, [army, fleet]},
                          {clyde, north_atlantic_ocean, [fleet]},
                          {clyde, norwegian_sea, [fleet]},
                          {edinburgh, liverpool, [army]},
                          {edinburgh, north_sea, [fleet]},
                          {edinburgh, norwegian_sea, [fleet]},
                          {edinburgh, yorkshire, [army, fleet]},
                          {liverpool, irish_sea, [fleet]},
                          {liverpool, north_atlantic_ocean, [fleet]},
                          {liverpool, wales, [army,fleet]},
                          {liverpool, yorkshire, [army]},
                          {london, english_channel, [fleet]},
                          {london, north_sea, [fleet]},
                          {london, wales, [army, fleet]},
                          {london, yorkshire, [army, fleet]},
                          {wales, english_channel, [fleet]},
                          {wales, irish_sea, [fleet]},
                          {wales, yorkshire, [army]},
                          {yorkshire, north_sea, [fleet]},
                          {brest, english_channel, [fleet]},
                          {brest, gascony, [army, fleet]},
                          {brest, mid_atlantic_ocean, [fleet]},
                          {brest, paris, [army]},
                          {brest, picardy, [army, fleet]},
                          {burgundy, belgium, [army]},
                          {burgundy, gascony, [army]},
                          {burgundy, marseilles, [army]},
                          {burgundy, paris, [army]},
                          {burgundy, picardy, [army]},
                          {gascony, marseilles, [army]},
                          {gascony, mid_atlantic_ocean, [fleet]},
                          {gascony, paris, [army]},
                          {gascony, spain, [army, fleet]},
                          {marseilles, gulf_of_lyon, [fleet]},
                          {marseilles, piedmont, [army, fleet]},
                          {marseilles, spain, [army, fleet]},
                          {paris, picardy, [army]},
                          {picardy, belgium, [army, fleet]},
                          {picardy, english_channel, [fleet]},
                          {berlin, baltic_sea, [fleet]},
                          {berlin, silesia, [army]},
                          {berlin, prussia, [army, fleet]},
                          {kiel, helgoland_bight, [fleet]},
                          {kiel, holland, [army, fleet]},
                          {kiel, berlin, [army, fleet]},
                          {kiel, baltic_sea, [fleet]},
                          {kiel, denmark, [army, fleet]},
                          {munich, ruhr, [army]},
                          {munich, berlin, [army]},
                          {munich, silesia, [army]},
                          {munich, kiel, [army]},
                          {munich, burgundy, [army]},
                          {prussia, baltic_sea, [fleet]},
                          {prussia, silesia, [army]},
                          {prussia, warsaw, [army]},
                          {prussia, livonia, [army, fleet]},
                          {ruhr, kiel, [army]},
                          {ruhr, burgundy, [army]},
                          {ruhr, holland, [army]},
                          {ruhr, belgium, [army]},
                          {silesia, warsaw, [army]},
                          {apulia, adriatic_sea, [fleet]},
                          {apulia, ionian_sea, [fleet]},
                          {naples, apulia, [army, fleet]},
                          {naples, ionian_sea, [fleet]},
                          {naples, tyrrhenian_sea, [fleet]},
                          {piedmont, gulf_of_lyon, [fleet]},
                          {rome, apulia, [army]},
                          {rome, naples, [army, fleet]},
                          {rome, tyrrhenian_sea, [fleet]},
                          {tuscany, piedmont, [army, fleet]},
                          {tuscany, rome, [army, fleet]},
                          {tuscany, tyrrhenian_sea, [fleet]},
                          {tuscany, gulf_of_lyon, [fleet]},
                          {venice, piedmont, [army]},
                          {venice, apulia, [army, fleet]},
                          {venice, tuscany, [army, fleet]},
                          {venice, rome, [army]},
                          {venice, adriatic_sea, [fleet]},
                          {finland, gulf_of_bothnia, [fleet]},
                          {finland, norway, [army]},
                          {finland, st_petersburg, [army, fleet]},
                          {finland, sweden, [army, fleet]},
                          {livonia, baltic_sea, [fleet]},
                          {livonia, gulf_of_bothnia, [baltic_sea]},
                          {livonia, moscow, [army]},
                          {livonia, st_petersburg, [army, fleet]},
                          {livonia, warsaw, [army]},
                          {moscow, sevastopol, [army]},
                          {moscow, st_petersburg, [army]},
                          {moscow, ukraine, [army]},
                          {moscow, warsaw, [army]},
                          {sevastopol, armenia, [army, fleet]},
                          {sevastopol, black_sea, [fleet]},
                          {sevastopol, rumania, [army, fleet]},
                          {sevastopol, ukraine, [army]},
                          {st_petersburg, barents_sea, [fleet]},
                          {st_petersburg, gulf_of_bothnia, [fleet]},
                          {ukraine, rumania, [army]},
                          {ukraine, warsaw, [army]},
                          {ankara, armenia, [army, fleet]},
                          {ankara, black_sea, [fleet]},
                          {ankara, constantinople, [army, fleet]},
                          {ankara, smyrna, [army]},
                          {armenia, black_sea, [fleet]},
                          {armenia, smyrna, [army]},
                          {armenia, syria, [army]},
                          {constantinople, aegean_sea, [fleet]},
                          {constantinople, black_sea, [fleet]},
                          {constantinople, bulgaria, [army, fleet]},
                          {constantinople, smyrna, [army, fleet]},
                          {smyrna, aegean_sea, [fleet]},
                          {smyrna, eastern_mediterranean, [fleet]},
                          {smyrna, syria, [army, fleet]},
                          {albania, adriatic_sea, [fleet]},               % Neutrals
                          {albania, greece, [army, fleet]},
                          {albania, ionian_sea, [fleet]},
                          {albania, serbia, [army]},
                          {belgium, english_channel, [fleet]},
                          {belgium, holland, [army, fleet]},
                          {belgium, north_sea, [fleet]},
                          {bulgaria, aegean_sea, [fleet]},
                          {bulgaria, black_sea, [fleet]},
                          {bulgaria, greece, [army, fleet]},
                          {bulgaria, rumania, [army, fleet]},
                          {bulgaria, serbia, [army]},
                          {denmark, baltic_sea, [fleet]},
                          {denmark, helgoland_bight, [fleet]},
                          {denmark, north_sea, [fleet]},
                          {denmark, skagerrak, [fleet]},
                          {denmark, sweden, [army, fleet]},
                          {greece, aegean_sea, [fleet]},
                          {greece, ionian_sea, [fleet]},
                          {greece, serbia, [army]},
                          {holland, helgoland_bight, [fleet]},
                          {holland, north_sea, [fleet]},
                          {north_africa, mid_atlantic_ocean, [fleet]},
                          {north_africa, tunis, [army, fleet]},
                          {north_africa, western_mediterranean, [fleet]},
                          {norway, barents_sea, [fleet]},
                          {norway, north_sea, [fleet]},
                          {norway, norwegian_sea, [fleet]},
                          {norway, skagerrak, [fleet]},
                          {norway, st_petersburg, [army, fleet]},
                          {norway, sweden, [army, fleet]},
                          {portugal, mid_atlantic_ocean, [fleet]},
                          {portugal, spain, [army, fleet]},
                          {rumania, black_sea, [fleet]},
                          {rumania, serbia, [army]},
                          {spain, gulf_of_lyon, [fleet]},
                          {spain, mid_atlantic_ocean, [fleet]},
                          {spain, western_mediterranean, [fleet]},
                          {sweden, baltic_sea, [fleet]},
                          {sweden, gulf_of_bothnia, [fleet]},
                          {sweden, skagerrak, [fleet]},
                          {tunis, ionian_sea, [fleet]},
                          {tunis, tyrrhenian_sea, [fleet]},
                          {tunis, western_mediterranean, [fleet]},
                          {aegean_sea, eastern_mediterranean, [fleet]},   % Water Bodies
                          {aegean_sea, ionian_sea, [fleet]},
                          {adriatic_sea, ionian_sea, [fleet]},
                          {baltic_sea, gulf_of_bothnia, [fleet]},
                          {barents_sea, norwegian_sea, [fleet]},
                          {eastern_mediterranean, ionian_sea, [fleet]},
                          {english_channel, irish_sea, [fleet]},
                          {english_channel, mid_atlantic_ocean, [fleet]},
                          {english_channel, north_sea, [fleet]},
                          {gulf_of_lyon, tyrrhenian_sea, [fleet]},
                          {gulf_of_lyon, western_mediterranean, [fleet]},
                          {helgoland_bight, north_sea, [fleet]},
                          {ionian_sea, tyrrhenian_sea, [fleet]},
                          {irish_sea, mid_atlantic_ocean, [fleet]},
                          {irish_sea, north_atlantic_ocean, [fleet]},
                          {mid_atlantic_ocean, north_atlantic_ocean, [fleet]},
                          {mid_atlantic_ocean, western_mediterranean, [fleet]},
                          {north_atlantic_ocean, norwegian_sea, [fleet]},
                          {north_sea, norwegian_sea, [fleet]},
                          {north_sea, skagerrak, [fleet]},
                          {tyrrhenian_sea, western_mediterranean, [fleet]}]],
                                                % set centers:
    [map:set_province_info (Map, Id, center, true) || Id <- [% Austria:
                                                             budapest,
                                                             trieste,
                                                             vienna,
                                                % England:
                                                             edinburgh,
                                                             liverpool,
                                                             london,
                                                % France:
                                                             brest,
                                                             marseilles,
                                                             paris,
                                                % Germany:
                                                             berlin,
                                                             kiel,
                                                             munich,
                                                % Italy:
                                                             naples,
                                                             rome,
                                                             venice,
                                                % Russia:
                                                             moscow,
                                                             sevastopol,
                                                             st_petersburg,
                                                             warsaw,
                                                % Turkey:
                                                             ankara,
                                                             constantinople,
                                                             smyrna,
                                                % Neutral:
                                                             belgium,
                                                             bulgaria,
                                                             denmark,
                                                             greece,
                                                             holland,
                                                             norway,
                                                             portugal,
                                                             rumania,
                                                             serbia,
                                                             spain,
                                                             sweden,
                                                             tunis]],
%% set original_owners (the nations which can build there)
    [map:set_province_info (Map, Id, original_owner, Owner) ||
        {Owner, Id} <- [{austria, bohemia},
                        {austria, budapest},
                        {austria, galicia},
                        {austria, trieste},
                        {austria, tyrolia},
                        {austria, vienna},
                        {england, clyde},
                        {england, edinburgh},
                        {england, liverpool},
                        {england, london},
                        {england, wales},
                        {england, yorkshire},
                        {france, brest},
                        {france, burgundy},
                        {france, gascony},
                        {france, marseilles},
                        {france, paris},
                        {france, picardy},
                        {germany, berlin},
                        {germany, kiel},
                        {germany, munich},
                        {germany, prussia},
                        {germany, ruhr},
                        {germany, silesia},
                        {italy, apulia},
                        {italy, naples},
                        {italy, piedmont},
                        {italy, rome},
                        {italy, tuscany},
                        {italy, venice},
                        {russia, finland},
                        {russia, livonia},
                        {russia, moscow},
                        {russia, sevastopol},
                        {russia, st_petersburg},
                        {russia, ukraine},
                        {russia, warsaw},
                        {turkey, ankara},
                        {turkey, armenia},
                        {turkey, constantinople},
                        {turkey, smyrna},
                        {turkey, syria}]],

    %% add province owner
    [map:set_province_info (Map, Prov, owner, Owner) || {Prov, Owner} <- [% Austria:
                                                    {bohemia,austria},
                                                    {budapest,austria},
                                                    {galicia,austria},
                                                    {trieste,austria},
                                                    {tyrolia,austria},
                                                    {vienna,austria},
                                                % England:
                                                    {clyde,england},
                                                    {edinburgh,england},
                                                    {liverpool,england},
                                                    {london,england},
                                                    {wales,england},
                                                    {yorkshire,england},
                                                % France:
                                                    {brest,france},
                                                    {burgundy,france},
                                                    {gascony,france},
                                                    {marseilles,france},
                                                    {paris,france},
                                                    {picardy,france},
                                                % Germany:
                                                    {berlin,germany},
                                                    {kiel,germany},
                                                    {munich,germany},
                                                    {prussia,germany},
                                                    {ruhr,germany},
                                                    {silesia,germany},
                                                % Italy:
                                                    {apulia,italy},
                                                    {naples,italy},
                                                    {piedmont,italy},
                                                    {rome,italy},
                                                    {tuscany,italy},
                                                    {venice,italy},
                                                % Russia:
                                                    {finland,russia},
                                                    {livonia,russia},
                                                    {moscow,russia},
                                                    {sevastopol,russia},
                                                    {st_petersburg,russia},
                                                    {ukraine,russia},
                                                    {warsaw,russia},
                                                % Turkey:
                                                    {ankara,turkey},
                                                    {armenia,turkey},
                                                    {constantinople,turkey},
                                                    {smyrna,turkey},
                                                    {syria,turkey}]],

                                                % add the units:
    [map:add_unit (Map, Unit, To) || {To, Unit} <-
                                               [{budapest, {army, austria}},
                                                {trieste, {fleet, austria}},
                                                {vienna, {army, austria}},
                                                {edinburgh, {fleet, england}},
                                                {liverpool, {army, england}},
                                                {london, {fleet, england}},
                                                {brest, {fleet, france}},
                                                {marseilles, {army, france}},
                                                {paris, {army, france}},
                                                {berlin, {army, germany}},
                                                {kiel, {fleet, germany}},
                                                {munich, {army, germany}},
                                                {naples, {fleet, italy}},
                                                {rome, {army, italy}},
                                                {venice, {army, italy}},
                                                {moscow, {army, russia}},
                                                {sevastopol, {fleet, russia}},
                                                {st_petersburg, {fleet, russia}},
                                                {warsaw, {army, russia}},
                                                {ankara, {fleet, turkey}},
                                                {constantinople, {army, turkey}},
                                                {smyrna, {army, turkey}}]],
    Map.

%% -----------------------------------------------------------------------------
%% @doc
%% Delete a map
%% @end
%% -----------------------------------------------------------------------------
-spec delete (map ()) -> ok.
delete (Map) ->
    true = digraph:delete (Map),
    ok.

