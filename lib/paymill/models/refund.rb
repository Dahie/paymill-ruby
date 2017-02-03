module Paymill
  class Refund < Base

    attr_reader :amount, :description, :transaction, :status, :livemode, :response_code

    def self.create( transaction, attributes = {} )
      raise ArgumentError unless create_with?( attributes.keys )
      api_key  = Paymill.api_key( attributes.delete(:division) || :default )
      response = Paymill.request( Http.post( name.demodulize.tableize, api_key, transaction.id, Restful.normalize( attributes ) ), api_key )
      new( response['data'] )
    end

    protected
    def self.mandatory_arguments
      [:amount]
    end

    def self.allowed_arguments
      [:amount, :description, :division]
    end

  end
end
