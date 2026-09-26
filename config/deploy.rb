# frozen_string_literal: true

require "mina/rails"
require "mina/bundler"
require "mina/git"
require "mina/rbenv"
require "mina/puma"

Dir["/lib/mina/*.rb"].each { |file| require file }

set :whenever_name, "production"
set :domain, "167.99.64.121"
set :deploy_to, "/var/www/rbg"
set :repository, "git@github.com:vonchristian/rbg_pos.git"
set :branch, "main"
set :user, "deploy"
set :force_asset_precompile, true
set :term_mode, nil
set :app_path, lambda { "#{fetch(:deploy_to)}/#{fetch(:current_path)}" }
set :stage, "production"
# NOTE (Rails 8): place the production master key at shared/config/master.key
# (or export RAILS_MASTER_KEY). Run Solid Queue workers via a supervised
# `bin/jobs` process (systemd) alongside Puma; `rails:assets_precompile`
# below triggers jsbundling (yarn build) + cssbundling (yarn build:css).
set :shared_paths, ["config/database.yml", "config/master.key", "log", "tmp/log", "public/system", "tmp/pids", "tmp/sockets"]
set :shared_dirs, fetch(:shared_dirs, []).push("public/assets").push("public/packs").push("public/storage").push("storage")

# mina-puma (untitledkingdom/mina-puma) still passes `-d`/`--daemon` to `puma`,
# a flag Puma removed in 5.0. Puma 6.6.0 rejects it with
# `OptionParser::AmbiguousOption`, so `puma:start` never boots. Re-declare the
# task without `-d`, backgrounding it with `nohup ... &` instead so it survives
# the SSH session ending.
Rake::Task["puma:start"].clear_actions
namespace :puma do
  task start: :remote_environment do
    puma_port_option = "-p #{fetch(:puma_port)}" if set?(:puma_port)

    comment "Starting Puma..."
    command %[
      if [ -e "#{fetch(:pumactl_socket)}" ]; then
        echo 'Puma is already running!';
      else
        if [ -e "#{fetch(:puma_config)}" ]; then
          cd #{fetch(:puma_root_path)} && \
            nohup #{fetch(:puma_cmd)} -q -e #{fetch(:puma_env)} -C #{fetch(:puma_config)} \
            >> "#{fetch(:puma_stdout)}" 2>> "#{fetch(:puma_stderr)}" < /dev/null &
        else
          cd #{fetch(:puma_root_path)} && \
            nohup #{fetch(:puma_cmd)} -q -e #{fetch(:puma_env)} -b "unix://#{fetch(:puma_socket)}" #{puma_port_option} \
            -S #{fetch(:puma_state)} --pidfile #{fetch(:puma_pid)} --control 'unix://#{fetch(:pumactl_socket)}' \
            >> "#{fetch(:puma_stdout)}" 2>> "#{fetch(:puma_stderr)}" < /dev/null &
        fi
        disown
      fi
    ]
  end
end

# Optional settings:
#   set :user, 'foobar'    # Username in the server to SSH to.
#   set :port, '30000'     # SSH port number.
# set :forward_agent, true     # SSH forward_agent.

# This task is the environment that is loaded for most commands, such as
# `mina deploy` or c`mina rake`.
task :remote_environment do
  invoke :"rbenv:load"
end

# Put any custom mkdir's in here for when `mina setup` is ran.
# For Rails apps, we'll make some of the shared paths that are shared between
# all releases.

#########################################
desc "Deploys the current version to the server."
task deploy: :remote_environment do
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :"git:clone"
    invoke :"deploy:link_shared_paths"
    invoke :"bundle:install"
    invoke :"rails:db_migrate"
    invoke :"rails:assets_precompile"
    # command %{yarn install --check-files}
    # command %{NODE_ENV=production RAILS_ENV=production bundle exec rails webpacker:compile}
    invoke :"deploy:cleanup"

    on :launch do
      # invoke :'puma:restart'
      # invoke :'whenever:update'
    end
  end
end

namespace :deploy do
  desc "reload the database with seed data"
  task seed: :remote_environment do
    invoke :"rbenv:load"
    command "cd #{fetch(:current_path)}; bundle exec rails db:seed RAILS_ENV=#{fetch(:stage)}"
  end
end
