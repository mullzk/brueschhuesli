# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes a minimum and maximum.
# Any libraries that use a connection pool or another resource pool should
# be configured to provide at least as many connections as the number of
# threads. This includes Active Record's `pool` parameter in `database.yml`.
threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
threads threads_count, threads_count

if ENV['PUMA_SOCKET']
  bind "unix://#{ENV['PUMA_SOCKET']}"
else
  port ENV.fetch('PORT', 3000)
end

environment ENV.fetch('RAILS_ENV', 'development')

puma_dir = ENV["PUMA_DIRECTORY"].to_s
unless puma_dir.empty?
  directory puma_dir
  prune_bundler
  pidfile    "#{puma_dir}/tmp/pids/puma.pid"
  state_path "#{puma_dir}/tmp/pids/puma.state"
  activate_control_app "unix://#{puma_dir}/tmp/pids/pumactl.sock"
end

plugin :tmp_restart
