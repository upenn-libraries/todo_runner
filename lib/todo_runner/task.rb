module TodoRunner
  class Task
    attr_reader :options, :name

    def initialize name, options = {}, &block
      @name = name
      @options = options
      @block = block if block_given?
    end

    def next_step
      options[:next_step]
    end

    def on_fail_step
      options[:on_fail]
    end

    def next?
      return false if next_step.nil?
      true
    end

    def run
      return true if @block.nil?
      @block.call
    end
  end
end