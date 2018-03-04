require "thor"
require "dctl/kubernetes"

module Dctl::Kubernetes
  class Cli < Thor

    class_option :namespace, type: :string, aliases: :n
    class_option :env, type: :string

    desc "live-image", "Returns the active image for the given deployment"
    def live_image(service)
      puts Dctl::Kubernetes.live_image(service, k8s_opts)
    end

    desc "is-outdated", "Exit 1 if deployed image would be updated by a deploy, or 0 otherwise."
    long_desc <<~LONGDESC
      Check whether the currently deployed image is outdated and would be
      updated by a new deployment.

      This is determined by checking the tag specified in the compose file for
      this environment against a random pod in the corresponding k8s deployment.

      For example, if the tag in the compose file is `jutonz/app:4` and the live
      image is `jutonz/app:3`, this would exit with 0. If the tags matched this
      would exit with 1.

      This is useful for determining when it is possible to skip building new
      images, e.g with a CI/CD setup.

      Example:\x5
        export DCTL_ENV=prod\x5
        if dctl is-outdated app; then\x5
        \tdctl build app\x5
        \tdctl push app\x5
        else\x5
        \techo "app is up to date"\x5
        fi\x5
    LONGDESC
    def is_outdated(service)
      dctl = Dctl::Main.new dctl_opts
      compose_tag = dctl.image_tag service
      live_tag = Dctl::Kubernetes.live_image(service, k8s_opts)
      exit compose_tag == live_tag ? 1 : 0
    end

    no_commands do
      # Transform Thor's HashWithIndifferentAccess to a regular hash so it can
      # be passed to methods and treated as named arguments.
      def k8s_opts
        { namespace: options["namespace"] }
      end

      # Transform Thor's HashWithIndifferentAccess to a regular hash so it can
      # be passed to methods and treated as named arguments.
      def dctl_opts
        { env: options.fetch("env", "dev") }
      end
    end
  end
end