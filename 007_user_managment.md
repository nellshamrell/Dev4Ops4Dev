# User Management
[BEN WILL PROVIDE CONTENT FOR THIS PART]

# Creating a Deploy User with Chef

It's generally not a good idea to give an application root access to your machine when it is deploying.  In the section of the workshop we will create a new "deploy" user that Capistrano (our deployment tool) can use to deploy to our VM.

test/integration/deploy_user/serverspec/deploy_user_spec.rb
```bash
  require 'spec_helper'
  describe 'my_web_server_cookbook::deploy_user' do
    describe command('cut -d: -f1 /etc/passwd') do
      its(:stdout) { should match /deploy/ }
    end

    describe command('getent group sudo') do
      its(:stdout) { should match /deploy/ }
    end

    describe file('/etc/sudoers.d/deploy') do
      it { should be_file }
    end

    describe command('cat /etc/sudoers.d/deploy') do
      its(:stdout) { should match /deploy ALL=\(ALL\) NOPASSWD:ALL/ }
    end
  end
```

recipes/deploy_user.rb
```bash
  execute 'add deploy user' do
    command "sudo adduser deploy"
    action :run
    not_if "grep deploy /etc/passwd", :user => "deploy"
  end

  execute 'add deploy user' do
    command "sudo adduser deploy sudo"
    action :run
  end

  template '/etc/sudoers.d/deploy' do
    source 'deploy.erb'
  end
```

