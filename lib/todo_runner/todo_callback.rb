module TodoRunner
  class TodoCallback
    INTERVALS = %i{ all }

    attr_reader :interval
    attr_reader :name

    ##
    # @param [Symbol] interval +:all+
    # @param [Hash] options
    # @option options [Symbol] :name optional callback name
    # @yield Block to run when {#run} is invoke
    def initialize interval, options = {}, &block
      TodoCallback.validate_interval interval
      @interval = interval.to_sym
      @name     = options[:name]&.to_sym
      @block    = block if block_given?
    end

    ##
    # @return [Object] the return value of the {TodoCallback} block
    def run
      return true if @block.nil?
      @block.call
    end

    ##
    # @raise [TodoRunnerException] if interval is not in {INTERVALS}
    def self.validate_interval interval
      return if INTERVALS.include? interval.to_sym
      raise TodoRunnerException.new "Not a valid interval #{interval.inspect}"
    end

  end
end
