# config valid only for current version of Capistrano
lock '3.10.0'

ip_server = IO.readlines("config/provision/#{fetch(:stage)}")[1].delete!("\n")
DEPLOY_VARS = YAML.load_file("config/provision/group_vars/#{fetch(:stage)}")
PROVISION_VARS = YAML.load_file('config/provision/group_vars/all')

set :ssh_port, DEPLOY_VARS['ansible_port'] || PROVISION_VARS['ansible_port']

server ip_server, port: fetch(:ssh_port), roles: [:web, :app, :db], primary: true

set :repo_url, DEPLOY_VARS['repo_url'] || PROVISION_VARS['repo_url']
set :hostname, DEPLOY_VARS['app_hostname'] || PROVISION_VARS['app_hostname']

set :app_name, PROVISION_VARS['app_name']
set :user, PROVISION_VARS['deploy_user']
set :application, "#{fetch(:app_name)}_#{fetch(:stage)}"

set :puma_threads, [DEPLOY_VARS['puma_threads_min'], DEPLOY_VARS['puma_threads_max']]
set :puma_workers, DEPLOY_VARS['puma_workers']

# Don't change these unless you know what you're doing
set :pty,             false # false value required by sidekiq gem
set :use_sudo,        false
set :deploy_via,      :remote_cache
set :ssh_options,     forward_agent: true, user: fetch(:user), keys: %w(~/.ssh/id_rsa)
set :puma_preload_app, true
set :puma_worker_timeout, nil
set :puma_init_active_record, true
set :deploy_to,       "/home/#{fetch(:user)}/apps/#{fetch(:application)}"
set :puma_bind,       "unix://#{shared_path}/tmp/sockets/#{fetch(:application)}-puma.sock"
set :puma_state,      "#{shared_path}/tmp/pids/puma.state"
set :puma_pid,        "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log, "#{release_path}/log/puma.error.log"
set :puma_error_log,  "#{release_path}/log/puma.access.log"

set :sidekiq_config, -> { File.join(shared_path, 'config', 'sidekiq.yml') }

# Default branch is :master
set :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default value for :linked_files is []
set :linked_files, fetch(:linked_files, []).push()

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'pids', 'tmp/cache', 'vendor/bundle', 'public/system')

set :keep_releases, 5

namespace :puma do
  desc 'Create Directories for Puma Pids and Socket'
  task :make_dirs do
    on roles(:app) do
      execute "mkdir #{shared_path}/tmp/sockets -p"
      execute "mkdir #{shared_path}/tmp/pids -p"
    end
  end

  before :start, :make_dirs
end

namespace :deploy do
  desc 'Make sure local git is in sync with remote.'
  task :check_revision do
    on roles(:app) do
      unless `git rev-parse HEAD` == `git rev-parse origin/#{fetch(:branch)}`
        puts "WARNING: HEAD is not the same as origin/#{fetch(:branch)}"
        puts 'Run `git push` to sync changes.'
        exit
      end
    end
  end

  desc 'Create db and load shema. WARN: use it only for the first Deploy'
  task :setup_db do
    on roles(:app) do
      within release_path do
        execute :bundle, "exec rake RAILS_ENV=#{fetch(:rails_env)} \
          db:create"
        execute :bundle, "exec rake RAILS_ENV=#{fetch(:rails_env)} DISABLE_DATABASE_ENVIRONMENT_CHECK=1 \
          db:schema:load"
      end
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      invoke 'puma:restart'
    end
  end

  desc "Symlink shared env file"
  task :symlink_env_file do
    on roles(:app) do
      execute "ln -s #{deploy_to}/shared/config/environment.#{fetch(:stage)} #{release_path}/.env"
    end
  end

  before :starting,  :check_revision
  before :setup_db,   :symlink_env_file # make sure to keep it up-to-date with real secrets
  # before :migrate, :symlink_env_file # WARN: use this only for the non-first deploy
  before :migrate, :setup_db # WARN: use this only for the first deploy
end
