module Dctl::Kubernetes
  def self.live_image(service, namespace: nil)
    # Check if namespace exists
    if namespace && `kubectl get ns #{namespace}`.empty?
      error = "Could not find namespace #{namespace}"
      puts Rainbow(error).fg ERROR_COLOR
      exit 1
    end

    # Check if deployment exists
    deploy_check_command = "kubectl get deploy #{service}"
    deploy_check_command += " -n #{namespace}" if namespace
    if `#{deploy_check_command}`.empty?
      error = "Could not find deployment for #{service}"
      error += " in namespace #{namespace}" if namespace
      puts Rainbow(error).fg ERROR_COLOR
      exit 1
    end

    jsonpath = "{$.spec.template.spec.containers[:1].image}"
    live_image_command = "kubectl get deploy #{service}"
    live_image_command += " -ojsonpath='#{jsonpath}'"
    live_image_command += " -n #{namespace}" if namespace

    `#{live_image_command}`
  end
end
