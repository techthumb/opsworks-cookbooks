pg_data_directory = '/data' 

file '/etc/apt/sources.list.d/pgdg.list' do
  content 'deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main'
end
execute 'wget --quiet -O - http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | sudo apt-key add -'
execute 'sudo apt-get update'

%w(python-psycopg2 postgresql-9.3).each do | package_name |
  package package_name
end

service "postgresql" do
  action :stop
end

directory pg_data_directory do
  owner 'postgres'
  group 'postgres'
  action :create
end

execute 'pg_dropcluster 9.3 main'
execute 'pg_createcluster -d /data 9.3 main'
execute 'echo "host    all             all             0.0.0.0/0               md5" >> /etc/postgresql/9.3/main/pg_hba.conf'
execute %q(echo "listen_addresses='*'" >> /etc/postgresql/9.3/main/postgresql.conf)

service "postgresql" do
  action :start
end

db_name     = node[:opsworks][:stack][:name]
db_username = node[:opsworks][:stack][:name]
db_password = node[:postgresql][:password]

execute "createdb #{db_name}" do
  user 'postgres'
end

execute %Q(psql -c "CREATE USER #{db_username} WITH PASSWORD '#{db_password}'") do
  user 'postgres'
end

execute %Q(psql -c 'GRANT ALL PRIVILEGES ON DATABASE #{db_name} to #{db_username}') do
  user 'postgres'
end