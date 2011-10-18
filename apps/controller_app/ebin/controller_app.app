{application,controller_app,
             [{description,[]},
              {vsn,"1.0.0"},
              {registered,[]},
              {applications,[kernel,stdlib,service,datatypes,db]},
              {mod,{controller_app_app,[]}},
              {env,[{riak,{pb,{"127.0.0.1",8081}}},
                    {controller_app_workers,10}]},
              {modules,[controller,controller_app_app,controller_app_config,
                        controller_app_sup,controller_app_worker,
                        controller_app_worker_sup,session]}]}.