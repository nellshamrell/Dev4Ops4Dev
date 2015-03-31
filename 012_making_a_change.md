Change is inevitable in Software Engineering projects.  Let's practice deploying a change to the database schema.

Our development team has decided to add a table for customers so we can keep track of who has ordered what widget.  We're also adding two fields to the widgets table - ordered_by (which will keep track of what customer ordered the widget) and ordered_date (which will keep track of when the order was placed).  There needs to be a relationship between the two tables.

Let's say that our development team has made these changes in a branch called "add-new-feature."  Normally, this would be merged to master before we would deploy it, but for the sake of this workshop we're going to deploy the "add-new-feature" branch instead.


Make sure you're in your widgetworld directory:

```bash
  $ cd ~/widgetworld
```

First, STASH the changes you've made for Capistrano like this:

```bash
  $ git stash .
```

Then checkout the add-new-feature branch

```bash
  $ git checkout -b add-new-feature origin/add-new-feature
```

Then re-apply the changes you stashed like this:

```bash
  $ git stash pop
```

First, open up your config/deploy.rb file and uncomment this line:

```bash
  # ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp
```

So it looks like this:

```bash
   ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp
```

Now Capistrano will ask us which branch we want to deploy, rather than auto-deploying master.

Now let's deploy this branch to staging first.

```bash
  $ cap staging deploy
```

And go to your staging instance's IP address in your browser.

This is a good time to click around, just do some final navigating around the site just to make sure nothing is obviously blowing up.

Now to production

Run:

```bash
  $ cap production deploy
```

And checkout the production IP.

We've successfully deployed a change to production!


