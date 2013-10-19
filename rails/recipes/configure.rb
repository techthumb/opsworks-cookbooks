include_recipe "deploy"

node[:deploy].each do |application, deploy|
  deploy = node[:deploy][application]

  execute "restart Rails app #{application}" do
    cwd deploy[:current_path]
    command node[:opsworks][:rails_stack][:restart_command]
    action :nothing
  end

  deploy = node[:deploy][application]
  
  deploy_variables = {
    :db_host      => node[:opsworks][:layers][:lb][:instances].first[:private_ip]
    :db_username  => node[:opsworks][:stack][:name]
    :db_password  => node[:postgresql][:password]
    :environment  => deploy[:rails_env]
  }

  template "#{deploy[:deploy_to]}/shared/config/database.yml" do
    source "database.yml.erb"
    cookbook 'rails'
    mode "0660"
    group deploy[:group]
    owner deploy[:user]
    variables(deploy_variables)

    notifies :run, "execute[restart Rails app #{application}]"

    only_if do
      File.exists?("#{deploy[:deploy_to]}") && File.exists?("#{deploy[:deploy_to]}/shared/config/")
    end
  end
end