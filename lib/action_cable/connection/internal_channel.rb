module ActionCable
  module Connection
    module InternalChannel
      extend ActiveSupport::Concern

      def subscribe_to_internal_channel
        if connection_identifier.present?
          callback = -> (message) { process_internal_message(message) }
          @_internal_redis_subscriptions ||= []
          @_internal_redis_subscriptions << [ internal_redis_channel, callback ]

          pubsub.subscribe(internal_redis_channel, &callback)
          log_info "Registered connection (#{connection_identifier})"
        end
      end

      def unsubscribe_from_internal_channel
        if @_internal_redis_subscriptions.present?
          @_internal_redis_subscriptions.each { |channel, callback| pubsub.unsubscribe_proc(channel, callback) }
        end
      end

      private
        def process_internal_message(message)
          message = ActiveSupport::JSON.decode(message)

          case message['type']
          when 'disconnect'
            log_info "Removing connection (#{connection_identifier})"
            @websocket.close
          end
        rescue Exception => e
          log_error "There was an exception - #{e.class}(#{e.message})"
          log_error e.backtrace.join("\n")

          handle_exception
        end

    end
  end
end