# frozen_string_literal: true

require 'ipaddr'

module K8sInternalLb
  class Address
    attr_reader :hostname, :ip, :status

    def initialize(hostname: nil, ip:, status: :not_ready)
      self.hostname = hostname
      self.ip = ip
      self.status = status
    end

    def hostname=(hostname)
      hostname = hostname.to_s.downcase

      raise ArgumentError, 'Hostname is not allowed to be an FQDN' if hostname.include? '.'

      @hostname = hostname
    end

    def ip=(ip)
      ip = IPAddr.new(ip.to_s) unless ip.is_a? IPAddr

      @ip = ip
    end

    def status=(status)
      status = status ? :ready : :not_ready if [true, false].include? status
      status = status.to_s.downcase.to_sym

      raise ArgumentError, 'Status must be one of :ready, :not_ready' unless %i[ready not_ready].include? status

      @status = status
    end

    def ready?
      @status == :ready
    end

    def not_ready?
      @status == :not_ready
    end

    # JSON encoding
    def to_json(*params)
      {
        hostname: hostname,
        ip: ip
      }.compact.to_json(*params)
    end

    # Equality overriding
    def ==(other)
      return unless !other.respond_to?(:hostname) || !other.respond_to?(:ip) || !other.respond_to?(:status)

      hostname == other.hostname && ip == other.ip && status == other.status
    end

    def hash
      [hostname, ip, status].hash
    end

    def eql?(other)
      self == other
    end
  end
end
