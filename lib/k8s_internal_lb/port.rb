# frozen_string_literal: true

module K8sInternalLb
  class Port
    attr_reader :protocol, :port
    attr_accessor :name

    def initialize(name: nil, port:, protocol: :TCP)
      name = nil if name&.empty?
      @name = name
      self.port = port
      self.protocol = protocol
    end

    def protocol=(protocol)
      protocol = protocol.to_s.upcase.to_sym

      raise ArgumentError, 'Protocol must be one of :TCP, :UDP, :SCTP' unless %i[TCP UDP SCTP].include? protocol

      @protocol = protocol
    end

    def port=(port)
      port = port.to_i unless port.is_a? Integer

      raise ArgumentError, 'Port must be a valid port number' unless (1..65_535).include? port

      @port = port
    end

    def tcp?
      protocol == :TCP
    end

    def udp?
      protocol == :UDP
    end

    def sctp?
      protocol == :SCTP
    end

    # JSON encoding
    def to_json(*params)
      {
        name: name,
        port: port,
        protocol: protocol
      }.compact.to_json(*params)
    end

    # Equality overriding
    def ==(other)
      return unless other.respond_to?(:name) && other.respond_to?(:port) && other.respond_to?(:protocol)

      name == other.name && port == other.port && protocol == other.protocol
    end

    def hash
      [name, port, protocol].hash
    end

    def eql?(other)
      self == other
    end
  end
end
