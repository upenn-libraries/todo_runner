module TodoRunner
  ##
  # Encapsulation of a TodoRunner task.
  #
  # @attr_reader [Hash] options initialization options
  # @attr_reader [Symbol] name name of the task
  # @attr [Tempfile] todo_file from current *.todo file
  class Task
    attr_reader :options
    attr_reader :name

    ##
    # @param [Symbol] name the task name
    # @param [Hash] options initialization options
    # @option options [Symbol] :next_step name of step to take upon completion
    # @option options [Symbol] :on_fail name of step to take upon failure
    # @yield Block to run when {#run} is invoked.
    def initialize name, options = {}, &block
      @name = name
      @options = options.dup.freeze
      @block = block if block_given?
    end

    ##
    # @return [Symbol] next step name
    def next_step
      options[:next_step]
    end

    ##
    # @return [Symbol] fail step name
    def on_fail_step
      options[:on_fail]
    end

    ##
    # @return [Boolean] +true+ if there is a next step
    def next?
      return false if next_step.nil?
      true
    end

    ##
    # @param [TodoRunner::TodoFile] todo_file
    # @return [Object] the return value of the {Task} block
    def run todo_file
      return true if @block.nil?
      @block.call todo_file
    end
  end
end