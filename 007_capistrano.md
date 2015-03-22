cd back to home directory of VM

```bash
  $ cd
```

Clone Widget World application

```bash
  $ git clone git@github.com:nellshamrell/widgetworld.git
```

```bash
  $ cd widgetworld
```

open Gemfile

```bash
  $ vim Gemfile
```

Add this content

```bash
group :development do
  gem 'capistrano',  '~> 3.1'
  gem 'capistrano-rails', '~> 1.1'
  gem 'capistrano-rvm'
end
```

Then run:

```bash
  $ bundle
```


