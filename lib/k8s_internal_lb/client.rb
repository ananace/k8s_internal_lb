# frozen_string_literal: true

module K8sInternalLb
  class Client
    attr_accessor :kubeclient_options, :namespace, :auth_options, :ssl_options, :server, :api_version

    def self.instance
      @instance ||= Client.new
    end

    def initialize
      @kubeclient_options = {}
      @auth_options = {}
      @ssl_options = {}

      @namespace = nil
      @server = nil
      @api_version = 'v1'

      @services = {}

      return unless in_cluster?

      @server = 'https://kubernetes.default.svc'
      @namespace ||= File.read('/var/run/secrets/kubernetes.io/serviceaccount/namespace')
      if @auth_options.empty?
        @auth_options = {
          bearer_token_file: '/var/run/secrets/kubernetes.io/serviceaccount/token'
        }
      end

      return unless File.exist?('/var/run/secrets/kubernetes.io/serviceaccount/ca.crt')

      @ssl_options[:ca_file] = '/var/run/secrets/kubernetes.io/serviceaccount/ca.crt'
    end

    def in_cluster?
      Dir.exist? '/var/run/secrets/kubernetes.io'
    end

    def add_service(name, **data)
      if name.is_a? Service
        @services[name.name] = name
        return
      end

      data[:name] ||= name
      @services[name] = Service.new(**data)
    end

    def run
      @services.each do |name, service|
        logger.debug "Checking #{name} for interval"

        diff = (Time.now - service.last_update)
        next unless diff > service.interval

        logger.info "Interval reached on #{name}, running update"
        update(service)
      end
    end

    private

    def update(service, force: false)
      service = @services[service] unless service.is_a? Service

      old_endpoints = service.endpoints.dup
      service.update
      service.last_update = Time.now
      endpoints = service.endpoints

      return true if old_endpoints == endpoints && !force

      client.patch_endpoints(
        service[:name],
        {
          metadata: {
            annotations: {
              'com.github.ananace.k8s_internal_lb/timestamp': Time.now.to_i.to_s
            }
          },
          subsets: [
            service.to_subset
          ]
        },
        service[:namespace] || namespace
      )
    rescue StandardError => e
      raise e
    end

    def kubeclient
      @kubeclient ||= Kubeclient::Client.new(
        server,
        api_version,
        auth_options: auth_options,
        ssl_options: ssl_options,
        **kubeclient_options
      )
    end
  end
end
