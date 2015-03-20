test/integration/postgresql/serverspec/postgresql_spec.rb
require 'spec_helper'
describe 'my_web_server_cookbook::postgresql' do
  describe package('postgresql') do
    it { should be_installed }
  end

  describe user('postgres') do
    it { should exist }
  end

  describe command('sudo -u postgres -s psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname=\'deploy\'"') do
    its(:stdout) { should match /1/ }
  end

  describe command('sudo -u postgres -s psql postgres -tAc "\du"') do
    its(:stdout) { should match /deploy\|Create DB\|{}/ }
  end
end

recipes/postgresql.rb
include_recipe 'my_web_server_cookbook::default'

package 'postgresql'

execute "create new postgres user" do
  user "postgres"
  command "psql -c \"create user deploy with password 'deploy_password';\""
  not_if { `sudo -u postgres psql -tAc \"SELECT 1 FROM pg_roles WHERE rolname=\'deploy\'\" | wc -l`.chomp == "1" }
end

execute "create new postgres user" do
  user "postgres"
  command "psql -c \"ALTER USER deploy CREATEDB;\""
end
