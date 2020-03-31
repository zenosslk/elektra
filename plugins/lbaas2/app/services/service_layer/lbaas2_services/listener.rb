module ServiceLayer
  module Lbaas2Services
    module Listener

      def listener_map
        @listener_map ||= class_map_proc(::Lbaas2::Listener)
      end

      def listeners(filter = {})
        elektron_lb2.get('listeners', filter).map_to(
          'body.listeners', &listener_map
        )
      end

      def find_listener(id)
        elektron_lb2.get("listeners/#{id}").map_to(
          'body.listener', &listener_map
        )
      end

      def new_listener(attributes = {})
        listener_map.call(attributes)
      end

    end
  end
end