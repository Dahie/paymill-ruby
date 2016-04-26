module Paymill
  class Preauthorization < Base
    include Restful::Delete

    attr_reader :amount, :currency, :description, :status, :livemode, :payment, :client, :transaction, :response_code

    protected
    def self.create_with?( incoming_arguments )
      raise ArgumentError unless incoming_arguments.any? { |e| mutual_excluded_arguments.include? e } && ( incoming_arguments & mutual_excluded_arguments ).size == 1
      super( incoming_arguments - mutual_excluded_arguments )
    end

    def self.mandatory_arguments
      [:amount, :currency]
    end

    def self.allowed_arguments
      [:amount, :currency, :description, :division]
    end

    def self.mutual_excluded_arguments
      [:token, :payment]
    end
  end
end
