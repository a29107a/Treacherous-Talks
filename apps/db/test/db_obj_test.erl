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
-module (db_obj_test).

-include_lib ("eunit/include/eunit.hrl").

db_obj_index_test() ->
    Bucket = <<"a_bucket">>,
    Key = <<"I am a key">>,
    Value = "awesome value",
    Obj = db_obj:create(Bucket, Key, Value),
    
    Index = <<"index">>,
    IndexKey = <<"index key">>,
    IndexTup = {Index, IndexKey},
    IndexList = [IndexTup],
    Obj2 = db_obj:add_index(Obj, IndexTup),
    ?debugVal(Obj2),
    ?assertEqual(IndexList, db_obj:get_indices(Obj2)),

    Obj3 = db_obj:remove_index(Obj2, IndexTup),
    ?debugVal(Obj3),
    ?assertEqual([], db_obj:get_indices(Obj3)),

    Obj4 = db_obj:set_indices(Obj3, IndexList),
    ?debugVal(Obj4),
    ?assertEqual(IndexList, db_obj:get_indices(Obj4)).
    
    
    
