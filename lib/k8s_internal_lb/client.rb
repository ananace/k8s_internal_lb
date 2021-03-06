# frozen_string_literal: true

require 'time'

module K8sInternalLb
  class Client
    TIMESTAMP_ANNOTATION = 'com.github.ananace.k8s-internal-lb/timestamp'

    attr_accessor :kubeclient_options, :namespace, :auth_options, :ssl_options, :server, :api_version
    attr_accessor :sleep_duration
    attr_reader :services

    def self.instance
      @instance ||= Client.new
    end

    def in_cluster?
      # FIXME: Better detection, actually look for the necessary cluster components
      Dir.exist? '/var/run/secrets/kubernetes.io'
    end

    def add_service(name, **data)
      service = nil

      if name.is_a? Service
        service = name
        name = service.name
      else
        data[:name] ||= name
        service = Service.create(**data)
      end

      k8s_service = get_endpoint(service)
      raise 'Unable to find service' if k8s_service.nil?

      if k8s_service.metadata&.annotations&.to_hash&.key? TIMESTAMP_ANNOTATION
        ts = k8s_service.annotations[TIMESTAMP_ANNOTATION]
        if ts =~ /\A\d+\z/
          service.last_update = Time.at(ts.to_i)
        else
          service.last_update = Time.parse(ts)
        end
      end

      @services[name] = service
    end

    def remove_service(name)
      @services.delete name
    end

    def run
      loop do
        sleep_duration = @sleep_duration

        @services.each do |name, service|
          logger.debug "Checking #{name} for interval"

          diff = (Time.now - service.last_update)
          until_next = service.interval - diff
          sleep_duration = until_next if until_next.positive? && until_next < sleep_duration

          next unless diff >= service.interval

          logger.debug "Interval reached on #{name}, running update"
          update(service)
        end

        sleep sleep_duration
      end
    end

    private

    def initialize
      @sleep_duration = 5

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

    def logger
      @logger ||= Logging::Logger[self]
    end

    def update(service, force: false)
      service = @services[service] unless service.is_a? Service

      old_endpoints = service.endpoints.dup
      service.last_update = Time.now
      service.update
      endpoints = service.endpoints

      return true if old_endpoints == endpoints && !force

      logger.info "Active endpoints have changed for #{service.name}, updating cluster data to #{service.to_subsets.to_json}"

      kubeclient.patch_endpoint(
        service.name,
        {
          metadata: {
            annotations: {
              TIMESTAMP_ANNOTATION => Time.now.to_s
            }
          },
          subsets: service.to_subsets
        },
        service.namespace || namespace
      )
    rescue StandardError => e
      raise e
    end

    def get_service(service)
      kubeclient.get_service(service.name, service.namespace || namespace)
    rescue Kubeclient::ResourceNotFoundError
      nil
    end

    def get_endpoint(service)
      kubeclient.get_endpoint(service.name, service.namespace || namespace)
    rescue Kubeclient::ResourceNotFoundError
      nil
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
