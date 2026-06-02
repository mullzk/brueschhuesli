# frozen_string_literal: true

set :application, "brueschhuesli"
set :repo_url, "git@github.com:mullzk/brueschhuesli.git"
set :linked_dirs, %w[log tmp/pids public/system storage]
set :keep_releases, 5

set :default_env, { path: "/home/deploy-app/.local/share/mise/shims:$PATH" }

before "deploy:starting", :load_shared_env do
  on roles(:all) do
    env_content = capture("cat #{shared_path}/config/env 2>/dev/null || true")
    env_vars = {}
    env_content.each_line do |line|
      line = line.strip
      next if line.empty? || line.start_with?("#")
      key, value = line.split("=", 2)
      env_vars[key.strip] = value.to_s.strip.gsub(/\A["']|["']\z/, "") if key
    end
    SSHKit.config.default_env.merge!(env_vars)
  end
end

namespace :deploy do
  task :restart do
    on roles(:app) do
      state = shared_path.join("tmp/pids/puma.state")
      # First deploy before the control app exists: nothing to signal yet.
      next unless test :test, "-f", state
      within release_path do
        execute :bundle, :exec, :pumactl, "-S", state, "restart"
      end
    end
  end
  after :publishing, :restart
end
