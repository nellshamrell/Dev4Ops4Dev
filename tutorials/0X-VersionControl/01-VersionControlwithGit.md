## Setting up Git

[TO DO: Capture in a workstation setup Chef recipe?]
[NOTE: could be baked into a box image ]

Next, we will be using Git for source control.

[TO DO: Explain source control here?]

To install Git, run this command:

```bash
  $ sudo apt-get install git
```

### Connecting to Github

[TO DO: Explain Github]

If you have not already done so, create a [Github account](https://github.com/).  This will give us a place outside of our developer workstation to keep our Chef recipes, etc.

Now let's connect your developer workstation to your Github account.  To do this, first set up your global git name (this is what identifies you in your commits) through this command:

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

Next, you'll need to create an SSH key on your developer workstation and add it to your Github accout to allow you to pull and push repositories from/to Github.  Github provides [excellent instructions](https://help.github.com/articles/generating-ssh-keys/) on how to do this.  If you need help, please ask!
   
