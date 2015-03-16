# Setting Up Your Development Environment

We want all attendees of this workshop to develop in the same environment.  To do this, we will be using a combination of VirtualBox and Vagrant so that each attendee (no matter what OS their laptop is running on) will be able to develop from an Ubuntu Linux 14.04 virtual machine.  We are assuming some familiarity with the linux command line, but if you are not familiar please reach out to an instructor and your fellow students.

## What you will need to install on your laptop

VirtualBox
Vagrant

## Introduction to VirtualBox and Vagrant

[VirtualBox](https://www.virtualbox.org/) allows your system to run multiple virtual machines from your laptop's OS without needing to reboot or affect your laptop's OS.

[Vagrant](https://www.vagrantup.com/) is a wrapper for VirtualBox VMs which allows you to create portable work environments you can take from system to system.  It makes it easy to ssh into a virtual machine and interact with it the way you would interact with a cloud server.

## Setting up VirtualBox

Download the VirtualBox package appropriate for your Operating system [here](https://www.virtualbox.org/wiki/Downloads)
After it is downloaded and installed, follow the instructions [here](http://www.virtualbox.org/manual/ch01.html#idp91929072) to start up VirtualBox.

[TO DO: Decide if we want to provide Virtual Box installation packages on a USB stick to avoid hitting the wifi so hard]

## Setting up Vagrant

Download the Vagrant package appropriate for your Operating System [here](http://www.vagrantup.com/downloads)

[TO DO: Decide if we want to provide Vagrant installation packages on a USB stick to avoid hitting the wifi so hard]

### OS X

Follow the Vagrant setup instructions located [here](https://docs.vagrantup.com/v2/getting-started/index.html)

Create a new directory to host your workshop material.  Call it whatever you like.

Open up a terminal window and change directories into your workshop directory.  IE, if you created your workshop folder within your documents directory, you would navigate there by typing this in the terminal.

```bash
  $ cd Documents/my_workshop_folder
```

Head on down to the "Using Vagrant" section of these instructions.

### Windows 7

You must also install PuTTY (a Telnet and SSH client) and PuTTY gen (an RSA and DSA key generation utility).  You can downlad and install these [here](http://www.chiark.greenend.org.uk/~sgtatham/putty/download.html)

Create a new folder to host your workshop material.  Call it whatever you like, I created mine on my windows desktop but you can create it wherever you choose.

Hold down shift and right click on the project folder, then select "open command window here"

If you receive the error "Timed out while waiting for the machine to boot", follow these instructions:

1) Open up the VagrantFile in your project directory with Notepad (it's easiest do do this OUTSIDE of the command prompt)
2) Add these lines in between "Vagrant.configure(2) do |config|" and "end" lines

  ```bash
   config.vm.provider :virtualbox do |vb|
     vb.gui = true
   end
  ```
3) Save the file
4) Navigate back to your command prompt
5) Destroy the previous Vagrant virtual machine with this command

  ```bash
    $ vagrant destroy
  ```
6) The start the

Source: this [Stack Overflow Answer](http://stackoverflow.com/a/22575302).

Head on down to the "Using Vagrant" section of these instructions.

### Windows 8.1

TODO

### Linux

TODO

## Starting Vagrant

Let's create a Vagrant box that runs Ubuntu 14.04 LTS (Trusty Tahr).  We've created an image that is based on Trusty, with a few tools added.

TODO - instructions on how to find basebox image

In your project directory (using terminal if you're on a Mac or Linux box, using the command prompt if you're on a Windows box) type in this command:

```bash
  $ vagrant box add dev4ops4dev $USB_STICK_PATH/dev4ops4dev.box
```

This will locate the workshop image, and load it into Vagrant's library of boxesunder the name 'dev4ops4dev'.  Now Vagrant will be able to create a running VM based on that box!

```bash
  $ vagrant init dev4ops4dev
```

This will create a Vagrantfile in the project directory, which will allow us to configure our Vagrant box.  Go ahead and open it up and take a look through if you like.

Then run this command to start up your new Vagrant box:

```bash
  $ vagrant up
```

## SSHing into a Vagrant Box

Now it's time to SSH into your new Vagrant box so we can use it as a development environment!  The procedure for doing this varies slightly by Operating System, so please follow the appropriate instructions below.

### OS X or Linux

In your project folder (make sure it's the same directory with the Vagrant file you just created), run this command:

```bash
  your-laptop $ vagrant ssh
```

This will log you into your Vagrant box as the user 'vagrant', which has passwordless sudo.

### Windows 7 or 8.1

[ TODO ]

## Look around

Look around!  Your development machine should have some tools - some familiar, some perhaps not:

```bash
  vagrant@d4o4d-workshop $ for cmd in "nano vim emacs git vagrant tugboat chef rubocop foodcritic rspec"; do $cmd --version; done
```

Also notice that the prompt has changed, indicating that you on another machine - VM within your laptop!:

```bash
  vagrant@d4o4d-workshop $ uname -a
```



## Vagrant Basics

At this point, you only need to know a bit about Vagrant.  We'll add more as we go along.

### The Vagrant Directory Mount

You can pass files directly into and out of your vagrant instance using the /vagrant area, which is mounted on the directory on the host containing the Vagrantfile.

NOTE: this works seamlessly for VirtualBox-based VMs.  Later, we may work on other systems, in which this feature has different behavior.

### Handy Vagrant Commands

#### vagrant init BOXNAME

As you saw above, you use init to start a new project.  Given the name of a Vagrant box, it will create a Vagrantfile with default settings, which will tell it to create a VM from the box.

#### vagrant up

When run in a directory with a Vagrantfile, this will create a VM if one does not exist, or resume one if it has been suspended.

#### vagrant ssh and vagrant ssh-config

'vagrant ssh-config' tells you the settings it would use to connect to the VM.  'vagrant ssh' connects using the command line SSH, if available.

#### vagrant halt

Tells the guest operating system to perform a graceful shutdown.  Add --force to pull the plug immediately.

#### vagrant destroy

Force-halts the guest, then deletes the instance or disk image.  No going back - once it's gone, it's gone.

## Next Steps

And that sets up your development environment for this workshop!  Now onto using it!

## Enrichment (Optional)

### How did we make the workshop box?

We started with a base ubuntu image, which we got via Vagrant Atlas:

```bash
  $ vagrant init ubuntu/trusty64
  $ vagrant up
  $ vagrant ssh
```

### APT cache update

The first thing we want to do is update the operating system on our Vagrant box.  To do this in Ubuntu 14.04, run:

```bash
  vagrant@d4o4d-workshop $ sudo apt-get update
```

### Setting up Chef

We'll be using Chef throughout this workshop to set up a webserver, so let's get the ChefDK (Chef Developer Kit) installed on your Vagrant box.

Run this command:

```bash
  vagrant@d4o4d-workshop $ curl -L https://www.chef.io/chef/install.sh | sudo bash -s -- -P chefdk
```

This will take a few minutes.  Once it is complete (you'll see a message that says "Thank you for installing Chef Development Kit!"), verify that ChefDK installed like this:

```bash
  vagrant@d4o4d-workshop $ chef --version
```

You should see something along the lines of "Chef Development Kit Version: 0.4.0"

### Configuring Ruby

We'll be using Ruby to create Chef code.  Although ChefDK does come with a current version of Ruby, there is also an earlier version of Ruby already installed on our Ubuntu 14.04 system.

We need to configure are our development environment to use the ChefDK version of Ruby, rather than the system version of Ruby.  To do this, first run:

```bash
  vagrant@d4o4d-workshop $ which ruby
```

If it returns something like:

```bash
  usr/bin/ruby
```

That means your development environment is using the system ruby, rather than the ChefDK version of Ruby.  To fix this, run:

```bash
  vagrant@d4o4d-workshop $ echo 'eval "$(chef shell-init bash)"' >> ~/.bash_profile
```

This adds a line to your .bash_profile file, telling it to use the ChefDK version of Ruby.

Now we need to apply this change.  To do this, run:

```bash
  vagrant$ source ~/.bash_profile
```

Then re-run:

```bash
  vagrant@d4o4d-workshop $ which ruby
```

It should now return:

```bash
  /opt/chefdk/embedded/bin/ruby
```

### Editors

We installed several editors to suit various tastes.  As a safe default, we set EDITOR to nano in vagrant's .bash_profile .

```bash
  sudo apt-get install emacs24-nox emacs24-el vim nano joe 
  sudo apt-get install tree

### Chef, Vagrant, and DigitalOcean drivers

We'll be doing some development using Chef and a cloud provider, so we need to install Vagrant within the VM.

```bash
  echo 'eval "$(chef shell-init bash)"' >> ~/.bash_profile
  sudo apt-get install git
  wget https://dl.bintray.com/mitchellh/vagrant/vagrant_1.7.2_x86_64.deb && sudo dpkg -i vagrant_1.7.2_x86_64.deb && rm vagrant_1.7.2_x86_64.deb
  vagrant plugin install vagrant-omnibus
  vagrant plugin install vagrant-digitalocean
  gem install tugboat
```

### Miscellanea

There are some additional packages you will need to install to work with Ruby on Ubuntu.  You can install these with this command:

```bash
  vagrant@d4o4d-workshop $ sudo apt-get install git git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties
```
### Halt and Repack the Box

```bash
  vagrant@d4o4d-workshop $ exit
  your-laptop $ vagrant halt
  your-laptop $ vagrant package --output dev4ops4dev-workshop-0.1.0.box
```
