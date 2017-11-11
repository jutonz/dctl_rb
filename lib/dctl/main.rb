module Dctl
  class Main
    attr_reader :env, :settings

    def initialize(env: "dev")
      @env = env
      load_config!
    end

    ##
    # Generate the full tag for the given image, concatenating the org,
    # project, env, image name, and version.
    #
    # @example
    #   image_tag("app") # => jutonz/dctl-dev-app:1
    def image_tag(image)
      org       = settings.org
      project   = settings.project
      version   = versions[image]

      "#{org}/#{project}-#{env}-#{image}:#{version}"
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
    def load_config!
      Config.load_and_set_settings(config_path)
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
