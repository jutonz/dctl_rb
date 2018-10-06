module Dctl
  class Main
    attr_reader :env, :settings

    def initialize(env: "dev", config: nil)
      @env = env
      load_config!(config)
    end

    ##
    # Generate the full tag for the given image, concatenating the org,
    # project, env, image name, and version.
    #
    # Pass `version: nil` to exclude the version portion.
    #
    # @example
    #   image_tag("app") # => jutonz/dctl-dev-app:1
    def image_tag(image, version: current_version_for_image(image))
      org       = settings.org
      project   = settings.project

      tag = "#{org}/#{project}-#{env}-#{image}"
      tag += ":#{version}" if !version.nil?

      tag
    end

    def current_version_for_image(image)
      versions[image]
    end

    ##
    # Returns the path to the given image's data directory (which includes at
    # minimum the Dockerfile, plus any other relevant files the user may have
    # placed there).
    def image_dir(image)
      relative = File.join "docker", env, image
      File.expand_path relative, Dir.pwd
    end

    def image_dockerfile(image)
      File.expand_path "Dockerfile", image_dir(image)
    end

    def expand_images(*images)
      images = versions.keys if images.empty?
      images = Array(images)

      images.each { |image| check_image(image) }

      images
    end

    def bump(image)
      check_image(image)

      parsed  = parsed_compose_file
      service = parsed.dig "services", image
      old_tag = service["image"]
      puts "Found existing image #{old_tag}"

      version = versions[image].to_i
      new_tag = image_tag image, version: version + 1
      puts "New tag will be #{new_tag}"

      service["image"] = new_tag

      print "Updating..."
      File.write(compose_file_path, parsed.to_yaml)
      puts "done"

      # Cache bust
      @parsed_compose_file = nil
      @versions = nil

      puts Rainbow("#{image} is now at version #{version + 1}").fg :green
    end

    ##
    # Returns the path to the .dctl.yml file for the current project
    def config_path
      path = File.expand_path ".dctl.yml", Dir.pwd

      unless File.exist? path
        error = "Could not find config file at #{path}"
        puts Rainbow(error).red
        exit 1
      end

      path
    end

    ##
    # Confirms that there is an entry for the given image in the compose file
    # for this environment, and that the image tag within is formatted as we
    # expect it to be.
    #
    # Prints a warning if the tag has the wrong name, but errors out if the
    # service tag is not present
    #
    # Expected names look like org/project-env-image:version
    def check_image(image)
      tag = image_tag(image)

      # Check that a service exists for the image
      service = parsed_compose_file.dig "services", image
      unless service
        error = "The service \"#{image}\" is not present in the compose " \
          "file for this environment. Please add a service entry for " \
          "#{image} to #{compose_file_path}\n"
        puts Rainbow(error).fg :red

        puts <<~EOL
          It might look something like this:

          version: '3'
          services:
            #{image}:
              image: #{image_tag(image)}
        EOL
        exit 1
      end

      # Check that the image has the correct tag
      expected_tag = image_tag(image)
      actual_tag = service["image"]
      if actual_tag != expected_tag
        warning = "Expected the tag for the image \"#{image}\" to be " \
          "\"#{expected_tag}\", but it was \"#{actual_tag}\". While not " \
          "critical, this can cause issues with some commands."
        puts Rainbow(warning).fg :orange
      end
    end

    def versions
      @versions ||= begin
        images = parsed_compose_file["services"].keys
        version_map = {}

        images.each do |image|
          version_map[image] = parsed_compose_file["services"][image]["image"].split(":").last
        end

        version_map
      end
    end

    def parsed_compose_file
      @parsed_compose_file ||= YAML.load_file compose_file_path
    end

    ##
    # If there are user defined commands in .dctl.yml, dynamically add them to
    # the passed thor CLI so they may be executed.
    def define_custom_commands(klass)
      Array(settings.custom_commands).each do |command, args|
        klass.send(:desc, command, "[Custom Command] #{command}")
        klass.send(:define_method, command, -> do
          Array(args).each { |a| stream_output(a) }
        end)
      end
    end

    ##
    # Ensure the current project's .dctl.yml contains all the requisite keys.
    def check_settings!
      required_keys = %w(
        org
        project
      )

      required_keys.each do |key|
        unless Settings.send key
          error = "Config is missing required key '#{key}'. Please add it " \
            "to #{config_path} and try again."
          error += "\n\nFor more info, see https://github.com/jutonz/dctl_rb#required-keys"
          puts Rainbow(error).red
          exit 1
        end
      end
    end

    ##
    # Load the current project's config file, complaining if it does not exist
    # or is malformed.
    def load_config!(custom_config_path = nil)
      Config.load_and_set_settings(custom_config_path || config_path)
      check_settings!

      @settings = Settings
    end

    def compose_file_path
      path = File.expand_path "docker/#{env}/docker-compose.yml"

      unless File.exist? path
        err = "There is no docker compose file for env #{env} (I expected to find it at #{path})"
        puts Rainbow(err).red
        exit 1
      end

      path
    end
  end
end
