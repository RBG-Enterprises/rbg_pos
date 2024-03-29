require 'mina/rails'
require 'mina/bundler'
require 'mina/git'
require 'mina/rbenv'
require 'mina/puma'

Dir["/lib/mina/*.rb"].each { |file| require file }

set :whenever_name, 'production'
set :domain, '167.99.64.121'
set :deploy_to, '/var/www/rbg'
set :repository, 'git@github.com:vonchristian/rbg_pos.git'
set :branch, 'main'
set :user, 'deploy'
set :force_asset_precompile, true
set :term_mode, nil
set :app_path, lambda { "#{fetch(:deploy_to)}/#{fetch(:current_path)}" }
set :stage, 'production'
set :shared_paths,  ['config/database.yml', 'log', 'tmp/log', 'public/system', 'tmp/pids', 'tmp/sockets']
set :shared_dirs, fetch(:shared_dirs, []).push('public/assets').push('public/packs').push('public/storage')


# Optional settings:
#   set :user, 'foobar'    # Username in the server to SSH to.
#   set :port, '30000'     # SSH port number.
# set :forward_agent, true     # SSH forward_agent.

# This task is the environment that is loaded for most commands, such as
# `mina deploy` or c`mina rake`.
task :remote_environment do
  invoke :'rbenv:load'
end

# Put any custom mkdir's in here for when `mina setup` is ran.
# For Rails apps, we'll make some of the shared paths that are shared between
# all releases.


#########################################
desc "Deploys the current version to the server."
task :deploy => :remote_environment do
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile'
    # command %{yarn install --check-files}
    # command %{NODE_ENV=production RAILS_ENV=production bundle exec rails webpacker:compile}
    invoke :'deploy:cleanup'

    on :launch do
      # invoke :'puma:restart'
      # invoke :'whenever:update'
    end
  end
end

namespace :deploy do
  desc "reload the database with seed data"
  task :seed => :remote_environment do
    invoke :'rbenv:load'
    command "cd #{fetch(:current_path)}; bundle exec rails db:seed RAILS_ENV=#{fetch(:stage)}"
  end
end
