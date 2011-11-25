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
-module(system_utils_tests).

-include_lib("eunit/include/eunit.hrl").

generate_startup_order_test() ->
    SysConf = [{host, "stephan.pcs", [{release, web_frontend, [config_mods]},
                                      {release, xmpp_frontend, []}
                                     ]},
               {host, "jd.pcs", [{release, backend,
                                  [{db,[{riak,{pb,{"dilshod.pcs",8081}}},
                                        {db_workers,50}]}
                                  ]}]},
               {host, "dilshod.pcs", [{release, riak, []}]},
               {host, "tiina.pcs", [{release, backend,
                                     [{db,[{riak,{pb,{"andre.pcs",8081}}},
                                           {db_workers,50}]}
                                     ]}]},
               {host, "andre.pcs", [{release, riak, []}]}
              ],
    % actually we don't care whether dilshod's or andre's riak comes first,
    % but sort is stable so they should come in the order in the SysConf.
    % same goes for any other release type.
    Expected = [{"dilshod.pcs",riak},
                {"andre.pcs",riak},
                {"jd.pcs",backend},
                {"tiina.pcs",backend},
                {"stephan.pcs",web_frontend},
                {"stephan.pcs",xmpp_frontend}],
    Actual = system_utils:generate_startup_order(SysConf),
    ?assertEqual(Expected, Actual).