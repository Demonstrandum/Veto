app_path = File.expand_path "#{File.dirname __FILE__}/.."

listen "#{app_path}/tmp/unicorn.sock", backlog: 64
working_directory app_path
pid "#{app_path}/tmp/unicorn.pid"

#stderr_path "#{app_path}/log/unicorn.log"
#stdout_path "#{app_path}/log/unicorn.log"
