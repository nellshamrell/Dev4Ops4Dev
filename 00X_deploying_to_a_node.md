Now it's time to get this Chef cookbook running on a real VM.

[TO DO: Figure out pre-provisioning of Chef server for groups, assigning servers, getting SSH keys on servers, etc.]

Create nodes directory in cookbook

Create file #{IP_ADDRESS}.json in nodes directory

Add this content:

```bash

```

Install knife-solo
On your workstation:

```bash
  $ sudo gem install knife-solo --no-ri --no-rdoc
```

If you get an error, install ruby-dev on your machine with

```bash
  $ sudo apt-get install ruby-dev
```

Then re-run

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

Now bootstrap your node with chef:
```bash
  $ knife solo bootstrap root@#{IP ADDRESS FOR NODE}
```

And check out that IP address in your browser.  You should see

[INSERT IMAGE OF Apache2 Ubuntu Default Page]

We have a live, working web server!

