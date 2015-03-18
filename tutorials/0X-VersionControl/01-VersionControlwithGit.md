# Version Control with Git

So, now we have a working machine from which to do some development and some operations!  What do we need next?

Some code, of course!  

## Welcome to WidgetWorld!

The app we'll be supporting is called WidgetWorld.  [ TODO - Nell - blurb? ]

You can look at the code for WidgetWorld on GitHub.

  https://github.com/nellshamrell/widgetworld

You can browse around, look at it, read files.  You can even download ZIP files!

But how are we going to get the code?  The ZIP files seem like it would work fine.... but the developers all want to use "version control"....

## Why use Version Control?

We could just grab some code using a tarball, and go from there.  In fact, many of us have worked that way.  

### Problems without Version Control

Some problems start to crop up:

 * It's hard to sync copies of the code - which version is "right"?
 * It's hard to have one person work on a special feature while everyone else works on the main thing
 * You can't travel back in time and see what the code was like before - you don't get backups.

Version Control Systems (VCS) address these problems and more.  There have been many over the years - CVS, SVN, Perforce, VSS, and on and on - but today the dominant VCS by far is git.  

### Why git?

Mainly , git is distributed - that means that even though many people might have a copy of the code, no copy is more "authoritative" than any other, unless the humans decide to treat one copy as special.  You don't have to have a server, but you can if you want.  Git is also really fast at being distributed, and keeps some concepts separate that had been blurred before (like branching vs directory structure), which makes it easier and clearer to think about some things.

Another huge part of git's popularity is the handful of big git hosting services - Github and Bitbucket probably being the most famous.  10 years ago "participating in open-source software" meant emailing patches; today, it means opening a pull request on github, with public space for contribution, discussion, and maintainer handoff.

On the downside, git is really, really complex under the hood - or beautifully simple depending on who you ask.  Either way, it has a massive learing curve just past the "beginnner level".  It's also fairly unopinionated - you can make many different workflows using it, but it won't have one obvious right way to do something.

We'll learn just enough git today to do most common tasks, and talk a bit about the workflow.

## How do people Collaborate with Git and Github?

The most common workflow is something like this:

 1. You and Nell both have Github accounts.
 2. You are using Nell's code, and need to make a change to it that would benefit the world, or at least you.  
 3. You check the LICENSE and verify it's something you can contribute to. 
 4. You *fork* Nell's repo.  You now have a complete copy of the code in your github account.
 5. You *clone* your own copy of the repo to your computer.  Now you can locally edit the files.
 6. You *branch* the code, naming it "more-cowbell".  This lets you work on the more-cowbell feature, but if it takes longer than you thought, you can switch back to the regular, "master" branch anytime, then continue cowbell later.
 7. You keep *commit* as you go, in chunks of work that make sense, and hopefully leave the code in a working state after each commit.
 8. You *push* to send the changes from your development machine to your github account for safekeeping.  Until you push, the changes only exist on your machine - no matter how many time you comittted!
 9. When you think you want Nell to look at it, you issue a *pull request*, asking Nell to *pull* from your more-cowbell bracch to her master branch.  Discussion may ensue, and you can revise your PR by continuing to commit to your branch.

Let's try all that!

## Getting Setup

### Making an SSH Key

Most git servers authenticate with each other using SSH keys.  So, you'll need an SSH keypair.  

NOTE: if you already have a keypair and a github account, you can skip this; just make sure your ssh-agent is carrying your key when you are inside the Vagrant VM.

#### Generate the Key

```bash
  vagrant@d4o4d-workshop $ ssh-keygen -C "devops workshop key"
  # Accept location
  # Enter a secure passphrase & confirm
  vagrant@d4o4d-workshop $ ls -l ~/.ssh/
```

IMPORTANT - If anyone asks you to "Send me your SSH key", they are asking for the PUBLIC key - the .pub file.  Never share the other file, called the private key!

#### Start your SSH Agent

ssh-agent is a program that acts as a sort of keyring for you.  You can give it your private key half, and it will securely carry it around for you - including making it available to git, to prove you are who you claim to be.

First, let's see if your SSH agent is running.

```bash
  vagrant@d4o4d-workshop $ ssh-add -l 
```

If you see 'Could not establish a connection with your agent', that means it is not running (nearly any other result means it is.)

To start ssh-agent, run:

```bash
  vagrant@d4o4d-workshop $ eval $(ssh-agent)
```

#### Load your key into SSH Agent

```bash
  vagrant@d4o4d-workshop $ ssh-add .ssh/id_rsa
  # Provide your passphrase
```

Verify that the key was loaded:
```bash
  vagrant@d4o4d-workshop $ ssh-add -l 
```

### Configure your Local Git Client

To do this, set up your global git name (this is what identifies you in your commits) through this command:

```bash
  $ git config --global user.name "Your Name"
```

Now configure your global git email address (this will be included in your commits) through this command:

```bash
  $ git config --global user.email "your_email@your_email_domain.com"
```

Check that the values are stored correctly by running:

```bash
  $ git config --list
```

### Create a GitHub Account

If you have not already done so, create a [Github account](https://github.com/).  This will give us a place outside of our developer workstation to keep our Chef recipes, etc.

Once you have a github account, you will need to add your *public* SSH key to it.  Follow Github's instructions (https://help.github.com/articles/generating-ssh-keys/#step-4-add-your-ssh-key-to-your-account).

## Forking and Cloning a Repo

### Fork to make your own copy of the code

On the github website, make sure you are logged in.  Then find Nell's widgetworld repo, by searching for nellshamrell/widgetworld.  CLick the big Fork button!

Note: "fork" is not a 'git' command - it's a term used by Git hosting companies to represent a sever-side clone.

#### Sidebar: It's OK to Fork

In the past, when a project "forked," that meant there had been a rift in the project leadership, and a splinter faction had broken off, to create their own vision of the software.  A fork was irreversible, and divided communities.  With Github, forks are routine.  It simply means you are a making your own copy to work on, and it's easy to send your work back "upstream" to the original project - or, you can choose never to send your changes back upstream, while still receiving changes from the upstream project.  Popular projects like Chef might have thousands of forks!  Fork casually - it's no big deal.

### Clone to download the code from the git hosting service

You're now ready to fetch the code from the git hosting service Github, to your development machine.



## Making Changes

TODO

## Publishing Changes

TODO

## Submitting to the Maintainer

TODO
