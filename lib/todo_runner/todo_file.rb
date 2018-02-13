require 'tempfile'
require 'delegate'

module TodoRunner
  ##
  # A wrapper around Tempfile containing the data of +todo_path+ that adds
  # attributes +todo_path+ and +task_name+.
  #
  # Inherits methods of Tempfile and File.
  #
  # Important: Close TodoFile when you're done with it:
  #
  #   data = TodoFile.new 'path/to/my.todo', :something
  #   # do stuff
  #   data.close!
  #
  # Note that TodoFile behaves like a file object. Thus, if your todo file
  # is YAML, you can do something like:
  #
  #   todo_file = TodoFile.new 'path/to/my.todo', :something
  #   data = YAML.load todo_file
  #
  #
  # @attr_reader [String] todo_path path to the +*.todo+ file
  # @attr_reader [Symbol] task_name the name of the task
  class TodoFile < DelegateClass(Tempfile)
    attr_reader :todo_path
    attr_reader :task_name
    ##
    # @param [String] todo_path the path to the +*.todo+ file
    # @param [Symbol] task_name the name of the current task
    def initialize todo_path, task_name
      @todo_path = todo_path
      @task_name = task_name
      @tempfile  = build_tempfile
      super @tempfile
    end

    private

    def build_tempfile
      temp_base = "#{File.basename todo_path, '.todo'}-#{task_name}"
      tempfile  = Tempfile.new temp_base
      File.open(todo_path, 'r').each_line { |line| tempfile.puts line }
      tempfile.rewind
      tempfile
    end
  end
end