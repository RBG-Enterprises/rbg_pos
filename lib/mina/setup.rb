task :setup => :remote_environment do
  command %[mkdir -p "#{fetch(:deploy_to)}/#{fetch(:shared_path)}/log"]
  command %[chmod g+rx,u+rwx "#{fetch(:deploy_to)}/#{fetch(:shared_path)}/log"]

  command %[mkdir -p "#{fetch(:deploy_to)}/#{fetch(:shared_path)}/tmp/log"]
  command %[chmod g+rx,u+rwx "#{fetch(:deploy_to)}/#{fetch(:shared_path)}/tmp/log"]

  command %[mkdir -p "#{fetch(:deploy_to)}/#{fetch(:shared_path)}/config"]
  command %[chmod g+rx,u+rwx "#{fetch(:deploy_to)}/#{fetch(:shared_path)}/config"]

  command %[mkdir -p "#{fetch(:deploy_to)}/#{fetch(:shared_path)}/public/system"]
  command %[chmod g+rx,u+rwx "#{fetch(:deploy_to)}/#{fetch(:shared_path)}/public/system"]

  command %[mkdir -p "#{fetch(:deploy_to)}/shared/tmp/pids"]
  command %[chmod g+rx,u+rwx "#{fetch(:deploy_to)}/shared/tmp"]
  command %[chmod g+rx,u+rwx "#{fetch(:deploy_to)}/shared/tmp/pids"]

  command %[mkdir -p "#{fetch(:deploy_to)}/shared/tmp/sockets"]
  command %[chmod g+rx,u+rwx "#{fetch(:deploy_to)}/shared/tmp/sockets"]

  command %[touch "#{fetch(:deploy_to)}/#{fetch(:shared_path)}/tmp/log/stdout"]
  command %[touch "#{fetch(:deploy_to)}/#{fetch(:shared_path)}/tmp/log/stderr"]
  command %[touch "#{fetch(:deploy_to)}/#{fetch(:shared_path)}/tmp/pids/puma.pid"]
  command %[touch "#{fetch(:deploy_to)}/#{fetch(:shared_path)}/tmp/sockets/puma.sock"]
  command %[touch "#{fetch(:deploy_to)}/#{fetch(:shared_path)}/config/database.yml"]
  command %[touch "#{fetch(:deploy_to)}/#{fetch(:shared_path)}/config/secrets.yml"]
  command  %[echo "-----> Be sure to edit '#{fetch(:deploy_to)}/#{fetch(:shared_path)}/config/database.yml' and 'secrets.yml'."]

  if fetch(:repository)
    repo_host = fetch(:repository).split(%r{@|://}).last.split(%r{:|\/}).first
    repo_port = /:([0-9]+)/.match(fetch(:repository)) && /:([0-9]+)/.match(fetch(:repository))[1] || '22'

    command %[
      if ! ssh-keygen -H  -F #{repo_host} &>/dev/null; then
        ssh-keyscan -t rsa -p #{repo_port} -H #{repo_host} >> ~/.ssh/known_hosts
      fi
    ]
  end
end
