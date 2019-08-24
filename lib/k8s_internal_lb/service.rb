# frozen_string_literal: true

module K8sInternalLb
  class Service
    attr_reader :name
    attr_accessor :namespace, :interval, :last_update, :endpoints, :ports

    def self.create(type: :TCP, **params)
      raise ArgumentError, 'Must specify service type' if type.nil?

      klass = Services.const_get type
      raise ArgumentError, 'Unknown service type' if klass.nil?

      puts klass.inspect

      klass.new(**params)
    end

    def logger
      @logger ||= Logging::Logger[self]
    end

    def update
      raise NotImplementedError
    end

    def to_subsets
      grouped = endpoints.group_by(&:port)

      # TODO: Find all port combinations that result in the same list of ready
      #       and not-ready addresses, and combine them into a single pair of
      #       multiple ports.
      #
      # {
      #   1 => { active: [A, B], inactive: [C] },
      #   2 => { active: [A, B], inactive: [C] }
      # }
      # =>
      # {
      #   [1,2] => { active: [A, B], inactive: [C] }
      # }

      grouped = grouped.map do |p, g|
        {
          addresses: g.select(&:ready?).map(&:address),
          notReadyAddresses: g.select(&:not_ready?).map(&:address),
          ports: [p]
        }
      end

      # grouped = grouped.group_by { |s| s[:addresses] + s[:notReadyAddresses] }
      #                  .map do |_, s|
      #   v = s.first
      #
      #   v[:ports] = s.reduce([]) { |sum, e| sum << e[:ports] }
      #
      #   v
      # end

      grouped
    end

    protected

    def initialize(name:, namespace: nil, ports:, interval: 10, **_params)
      raise ArgumentError, 'Ports must be a list of Port objects' unless ports.is_a?(Array) && ports.all? { |p| p.is_a? Port }
      raise ArgumentError, 'Interval must be a positive number' unless interval.is_a?(Numeric) && interval.positive?

      @name = name
      @namespace = namespace
      @ports = ports
      @interval = interval
      @last_update = Time.at(0)
      @endpoints = []
    end
  end
end
