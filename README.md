# dctl

Choosing how to organize your application's containers across multiple environments is annoying. `dctl` can help.

By using a standardized directory structure across your apps, you can:
1. Easily onboard new developers
2. Not reinvent the wheel for every new app
3. Let other people handle the annoying parts of docker-compose for you

## Usage

Mostly use the same way you would use `docker-compose`, but without specifying a path to the `docker-compose.yaml` file.

Each command relies on information in the `docker-compose.yaml` for the given environment to determine things like tag versions.

The default environment is `dev`, but you can override this with `--env prod` etc.
  * This just tells dctl where to look for your compose file--it doesn't actually do anything different. See [Installation](#Installation) for more info.

* `dctl up`
* `dctl down`
* `dctl build`
* `dctl push`
* `dctl pull`
* `dctl create`
* `dctl rm`
* `dctl restart`
* `dctl ps`

### Targeting specific containers

Most commands also allow you to specify a specific image to target (defaulting to all images in your compose file)

* `dctl build app`
  * Just build your app container
* `dctl push psql`
  * Just push psql

### Nonstandard commands

There are also some non-compose commands to make your life easier

* `dctl connect [image]`
  * Start a new shell in a running container.
  * For instance, use `dctl connect app` to open a shell in your running `app` container.
* `dctl attach [image]`
  * Attach your current TTY to that of a running container.
  * This is useful if you've put a debugger or something similar and need to talk directly to a running container's current shell (docker-compose eats stdin/stdout/stderr so normally this isn't possible)
* `dctl bash [image]`
  * Spin up a new container using the given image and drop you in a shell.
  * While `connect` (above) creates a shell in a container which is already running, `bash` creates an entirely new container (and also does not require your stack to already be up).
* `dctl recreate [image]`
  * Stops, removes, builds, creates, and starts an image.
  * Useful if you've made a change to one container but don't want to restart your entire stack to have it reflected.
  * Options:
    * `--build` (`-b`) (default `true`)
      * Whether or not the image in question should be rebuilt before bringing it back up.
* `dctl cleanup`
  * Useful for policing the large numbers of built-but-unused containers which tend to accumulate when using docker.
  * Removes local images without tags and which are not referenced by other images.

## Installation

If using a Gemfile, add `gem 'dctl_rb'` and execute `bundle`. Otherwise just run `gem install dctl_rb`.

In your project directory, add a file `.dctl.yaml` like so:

```yaml
project: my_project
org: my_org
```

where `project` is the name of your current app (e.g. `dctl` for this repo) and `org` is the name of the docker organization where your containers are hosted (e.g. `jutonz`).

2. Create a top-level `docker` folder in your app

3. Inside `docker`, create a folder for each environment you want to support, e.g. `dev`, `staging`, `prod`

4. Inside those environment folders, create a folder for each necessary container, placing the `Dockerfile` and any related information inside

5. Inside each of those folders, create a `docker-compose.yaml` file which details how your containers relate.

A simple compose file might look like this:

```yaml
version: "3"
services:
  app:
    image: jutonz/dctl-dev-app:1
    volumes:
      - ../../:/root
```

6. Done! Your `docker` directory will probably look similar:

```
docker
├── dev
│   ├── app
│   │   ├── Dockerfile
│   │   └── init.sh
│   ├── docker-compose.yml
│   └── psql
│       ├── Dockerfile
│       ├── initdb.sh
│       └── startdb.sh
└── prod
    ├── app
    │   ├── Dockerfile
    │   └── init.sh
    ├── docker-compose.yml
    ├── nginx
    │   ├── Dockerfile
    │   ├── default.conf
    │   ├── init.sh
    │   └── nginx.conf
    └── psql
        ├── Dockerfile
        ├── backup.sh
        └── initdb.sh
```

## Config

### Required keys
  * `org` (required)
  * `project` (required)

### Optional keys
  * none yet

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jutonz/dctl)rb. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Dctl::Rb project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/dctl-rb/blob/master/CODE_OF_CONDUCT.md).
