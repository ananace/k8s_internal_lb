# frozen_string_literal: true

module K8sInternalLb
  class Endpoint
    attr_reader :address, :port, :status

    def initialize(address:, port:, status:)
      self.address = address
      self.port = port
      self.status = status
    end

    def address=(address)
      raise ArgumentError, 'Address must be an Address object' unless address.is_a? Address

      @address = address
    end

    def port=(port)
      raise ArgumentError, 'Port must be a Port object' unless port.is_a? Port

      @port = port
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
  end
end
