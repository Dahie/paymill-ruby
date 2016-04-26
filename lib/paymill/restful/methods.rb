module Paymill
  module Restful

    module All
      def all( arguments = {} )
        unless arguments.empty?
          order = "#{arguments[:order].map{ |e| "order=#{e.id2name}" }.join( '&' )}" if arguments[:order]
          filters = arguments[:filters].map{ |hash| hash.map{ |key, value| "#{key.id2name}=#{value.gsub( ' ', '+' ) }" }.join( '&' ) } if arguments[:filters]
          count = "count=#{arguments[:count]}" if arguments[:count]
          offset = "offset=#{arguments[:offset]}" if arguments[:offset]
          arguments = "?#{[order, filters, offset, count].reject { |e| e.nil? }.join( '&' )}"
        else
          arguments = ''
        end

        api_key = Paymill.api_key( arguments[:division] || :default )
        payload = Http.all( Restful.demodulize_and_tableize( name ), api_key, arguments )
        response = Paymill.request( payload, api_key )
        enrich_array_with_data_count( response['data'].map!{ |element| new( element ) }, response['data_count'] )
      end

      private
      def enrich_array_with_data_count( array, data_count )
        array.instance_variable_set( '@data_count', data_count )
        def array.data_count
          @data_count
        end
        array
      end
    end

    module Find
      def find( model, division: :default )
        model = model.id if model.is_a? self
        api_key = Paymill.api_key( division )
        payload = Http.get( Restful.demodulize_and_tableize( name ), api_key, model )
        response = Paymill.request( payload, api_key )
        new( response['data'] )
      end
    end

    module Create
      def create( arguments = {} )
        raise ArgumentError unless create_with?( arguments.keys )
        api_key = Paymill.api_key( arguments[:division] || :default )
        payload = Http.post( Restful.demodulize_and_tableize( name ), api_key, Restful.normalize( arguments ) )
        response = Paymill.request( payload, api_key )
        new( response['data'] )
      end
    end

    module Update
      def update( arguments = {} )
        arguments.merge! public_methods( false ).grep( /.*=/ ).map{ |m| m = m.id2name.chop; { m => send( m ) } }.reduce( :merge )

        api_key = Paymill.api_key( arguments[:division] || :default )
        payload = Http.put( Restful.demodulize_and_tableize( self.class.name ), api_key, self.id, Restful.normalize( arguments ) )
        response = Paymill.request( payload, api_key )
        source = self.class.new( response['data'] )
        self.instance_variables.each { |key| self.instance_variable_set( key, source.instance_variable_get( key ) ) }
      end
    end

    module Delete
      def delete( arguments = {} )
        api_key = Paymill.api_key( arguments[:division] || :default )
        payload = Http.delete( Restful.demodulize_and_tableize( self.class.name ), api_key, self.id, arguments )
        response = Paymill.request( payload, api_key )
        return self.class.new( response['data'] ) if self.class.name.eql? 'Paymill::Subscription'
        nil
      end
    end

    private
    def self.demodulize_and_tableize( name )
      "#{name.split('::').last.downcase}s"
    end

    def self.normalize( parameters = {} )
      attributes = {}.compare_by_identity
      parameters.each do |key, value|
        if value.is_a? Array
          value.each.with_index do |e, index|
            if e.is_a? Item
              e.instance_variables.each do |var|
                attributes["items[#{index}][#{var.to_s[1..-1]}]"] = e.instance_variable_get( var ) unless e.instance_variable_get( var ).to_s.empty?
              end
            else
              attributes["#{key.to_s}[]"] = e
            end
          end
        elsif value.is_a? Base
          attributes[key.to_s] = value.id
        elsif value.is_a? Time
          attributes[key.to_s] = value.to_i
        elsif value.is_a? Address
          value.instance_variables.each do |var|
            attributes["#{key.to_s}[#{var.to_s[1..-1]}]"] = value.instance_variable_get( var ) unless value.instance_variable_get( var ).to_s.empty?
          end
        else
          attributes[key.to_s] = value unless value.nil?
        end
      end
      attributes
    end
  end

  module Http
    def self.all( endpoint, api_key, arguments )
      request = Net::HTTP::Get.new( "/#{Paymill.api_version}/#{endpoint}#{arguments}" )
      request.basic_auth( api_key, '' )
      request
    end

    def self.get( endpoint, api_key, id )
      request = Net::HTTP::Get.new( "/#{Paymill.api_version}/#{endpoint}/#{id}" )
      request.basic_auth( api_key, '' )
      request
    end

    def self.post( endpoint, api_key, id = nil, arguments )
      request = Net::HTTP::Post.new( "/#{Paymill.api_version}/#{endpoint}/#{id}" )
      request.basic_auth( api_key, '' )
      request.set_form_data( arguments )
      request
    end

    def self.put( endpoint, api_key, id, arguments )
      request = Net::HTTP::Put.new( "/#{Paymill.api_version}/#{endpoint}/#{id}" )
      request.basic_auth( api_key, '' )
      request.set_form_data( arguments )
      request
    end

    def self.delete( endpoint, api_key, id, arguments )
      arguments = arguments.map { |key, value| "#{key.id2name}=#{value}" }.join( '&' )
      arguments = "?#{arguments}" unless arguments.empty?
      request = Net::HTTP::Delete.new( "/#{Paymill.api_version}/#{endpoint}/#{id}#{arguments}" )
      request.basic_auth( api_key, '' )
      # request.set_form_data( arguments ) unless arguments.empty?
      request
    end
  end
end
