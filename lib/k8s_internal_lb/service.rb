# frozen_string_literal: true

module K8sInternalLb
  class Service
    attr_reader :name
    attr_accessor :namespace, :interval, :last_update, :endpoints, :ports

    def self.new(type: :TCP, **params)
      raise ArgumentError, 'Must specify service type' if type.nil?

      klass = Services.const_get type
      raise ArgumentError, 'Unknown service type' if klass.nil?

      klass.new(**params)
    end

    def initialize(name:, namespace: nil, ports:, interval: 10, **_params)
      raise ArgumentError, 'Ports must be a list of Port objects' unless ports.is_a?(Array) || ports.all? { |p| p.is_a? Port }
      raise ArgumentError, 'Interval must be a positive number' unless interval.is_a?(Numeric) || interval.positive?

      @name = name
      @namespace = namespace
      @ports = ports
      @interval = interval
      @last_update = Time.new(0)
      @endpoints = []
    end

    def update
      raise NotImplementedError
    end

    def to_subset
      {
        addresses: endpoints.select(&:ready?).to_json,
        notReadyAddresses: endpoints.select(&:not_ready?).to_json,
        ports: ports.to_json
      }.to_json
    end
  end
end
