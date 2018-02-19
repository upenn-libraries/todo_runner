module TodoRunner
  module CallbackHandler

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      ##
      # @param [TodoRunner::TodoCallback] callback
      def add_after_callback callback
        after_callbacks[callback.interval] << callback
      end

      ##
      # @param [TodoRunner::TodoCallback] callback
      def add_before_callback callback
        before_callbacks[callback.interval] << callback
      end

      def after_callbacks
        @after_callbacks ||= Hash.new { |hash, key| hash[key] = [] }
      end

      def before_callbacks
        @before_callbacks ||= Hash.new { |hash, key| hash[key] = [] }
      end

      def run_before interval
        before_callbacks[interval.to_sym].each {|cb| cb.run}
      end

      def run_after interval
        after_callbacks[interval.to_sym].each {|cb| cb.run}
      end

      def clear
        after_callbacks.clear
        before_callbacks.clear
      end
    end
  end
end
