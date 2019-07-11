# frozen_string_literal: true

require 'ipaddr'

module K8sInternalLb
  class Address
    attr_reader :hostname, :ip

    def initialize(hostname: nil, ip:)
      self.hostname = hostname
      self.ip = ip
    end

    def hostname=(hostname)
      if hostname.nil? || hostname.empty?
        @hostname = nil
        return
      end

      hostname = hostname.to_s.downcase

      raise ArgumentError, 'Hostname is not allowed to be an FQDN' if hostname.include? '.'

      @hostname = hostname
    end

    def ip=(ip)
      ip = IPAddr.new(ip.to_s) unless ip.is_a? IPAddr

      @ip = ip
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
      return unless other.respond_to?(:hostname) && other.respond_to?(:ip)

      hostname == other.hostname && ip == other.ip
    end

    def hash
      [hostname, ip].hash
    end

    def eql?(other)
      self == other
    end
  end
end
