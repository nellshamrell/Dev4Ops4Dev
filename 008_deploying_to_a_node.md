# Provisioning a Server

We're going to provision our test instance on Digital Ocean using the (knife digital ocean plug)[https://github.com/rmoriz/knife-digital_ocean]

Go ahead and install the plugin on your workstation using this command.

```bash
  $ sudo chef gem install knife-digital_ocean
```

If you get an error, install ruby-dev on your machine with

```bash
  $ sudo apt-get install ruby-dev
```

Then re-run

```bash
  $ sudo gem install knife-digital_ocean
```

Next, you need to add the authorization token provided to you by the instructors to your knife config

.chef/knife.rb
```bash
knife[:digital_ocean_access_token]   = 'token_provided_by_instructors'
```

Now let's spin up a testing node!  Choose ONE person in your group to run this command to spin up a live VM on Digital Ocean - this will be our testing environment.

```bash
  $ knife digital_ocean droplet create --server-name testing-vm-#{group number}.vm.io --image ubuntu-14-04-x64 --location sfo1 --size 1gb --ssh-keys #{key num provided by instructors}
```

Take note of the IP address returned in the output and make sure to pass it on to each of your group members.

You should eventually see output that looks similar to this:

```bash
  Waiting for IPv4-Addressdone
  IPv4 address is: 192.241.201.66
  Waiting for sshd:done
  192.241.201.66
```

# Configuring Your Server
Now it's time to get this Chef cookbook running on a real VM.

## Installing knife-solo

We're using a plugin for knife called (knife-solo)[https://github.com/matschaffer/knife-solo]

```bash
  $ sudo chef gem install knife-solo --no-ri --no-rdoc
```

Test knife-solo setup
```bash
  $ knife solo
```

Should see something similar to:

FATAL: Cannot find sub command for: 'solo'
Available solo subcommands: (for details, knife SUB-COMMAND --help)

** SOLO COMMANDS **
  knife solo bootstrap [USER@]HOSTNAME [JSON] (options)
  knife solo clean [USER@]HOSTNAME
  knife solo cook [USER@]HOSTNAME [JSON] (options)
  knife solo init DIRECTORY
  knife solo prepare [USER@]HOSTNAME [JSON] (options)```bash
```

## Node Config

Now we need to define a json file which tells Chef solo what cookbooks to install on the testing node.

First, create a nodes directory in your cookbook.

```bash
  $ mkdir nodes
```

Now create a json file for your node using it's ip address.

```bash
  $ touch nodes/[your_nodes_ip_address].json
```

Now open up the json file and the add this content to run each of the recipes in the cookbook.

```bash
  {
    "run_list": [
      "recipe[my_web_server_cookbook::default]",
      "recipe[my_web_server_cookbook::passenger]",
      "recipe[my_web_server_cookbook::ruby]",
      "recipe[my_web_server_cookbook::postgresql]",
      "recipe[my_web_server_cookbook::user]"
      ],
  }
```

## Bootstrapping your node

Now bootstrap your node with chef:
```bash
  $ knife solo bootstrap root@#{IP ADDRESS FOR NODE}
```

And check out that IP address in your browser.  You should see your custom apache page!

We have a live, working web server!
