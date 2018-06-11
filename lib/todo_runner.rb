require 'tempfile'
require 'set'
require 'todo_runner/todo_runner_exception'
require 'todo_runner/file_renaming'
require 'todo_runner/callback_handler'
require 'todo_runner/version'
require 'todo_runner/task'
require 'todo_runner/definition_proxy'
require 'todo_runner/worker'
require 'todo_runner/todo_file'
require 'todo_runner/todo_callback'

module TodoRunner
  # TODO: ?? Add before, after callbacks before|after(:each|:all)
  # TODO: Decide how to handle errors and exceptions, including what to do with the file names and closing TodoFile instances
  # TODO: Logging????
  #
  include CallbackHandler
  include FileRenaming

  DEFAULT_TASKS = %i{ STOP SUCCESS FAIL ERROR }.freeze
  TERMINAL_TASKS = %i{ STOP SUCCESS FAIL }

  @registry  = {}
  @start     = nil
  @todo_file = nil

  @registry[:STOP] = Task.new :STOP do
    puts 'STOPPING'
  end

  @registry[:SUCCESS] = Task.new :SUCCESS do
    puts 'SUCCESS!'
  end

  @registry[:FAIL] = Task.new :FAIL do
    puts 'FAILED!'
  end

  @registry[:ERROR] = Task.new :ERROR do
    puts 'ERROR!'
  end

  ##
  # Define the TodoRunner. For example,
  #
  #   require 'yaml'
  #
  #   TodoRunner.define do
  #     # we have to say where to start
  #     start :mix
  #
  #     task :mix, on_fail: :FAIL, next_step: :bake do |todo_file|
  #       data = YAML.load todo_file
  #       recipe = data['Ingredients']
  #       # mix the cake
  #     end
  #
  #     task :bake, on_fail: :FAIL, next_step: :cool do |todo_file|
  #       data = YAML.load todo_file
  #       how_to_bake = data['Baking']
  #       # baking code
  #     end
  #
  #     TASK :cool, on_fail: :FAIL, next_step: :mix_icing do |todo_file|
  #       #
  #     end
  #
  #     task :mix_icing, on_fail: :FAIL, next_step: :ice_cake do |todo_file|
  #       #
  #     end
  #
  #     task :ice_cake, on_fail: :FAIL, next_step: :SUCCESS do |todo_file|
  #       #
  #     end
  #   end
  #
  # Note that current of {TodoFile} can be accessed inside each block if the
  # +todo_file+ argument is provided.
  def self.define &block
    clear # make sure there's nothing hanging around
    definition_proxy = DefinitionProxy.new
    definition_proxy.instance_eval &block
  end

  ##
  # registry of all tasks by name.
  # @return [Hash]
  def self.registry
    @registry
  end

  ##
  # Set start task.
  #
  # @param [Symbol] name
  def self.start= name
    @start = name
  end

  ##
  # Get start task name; e.g., +:mix+.
  #
  # @return [Symbol]
  def self.start
    @start
  end

  ##
  # Return +true+ if +name+ is +nil+ or in the list of {TERMINAL_TASKS}.
  #
  # @return [Boolean]
  def self.terminal_task? name
    return true if name.nil?
    TERMINAL_TASKS.include? name
  end

  ##
  # Run {TodoRunner} for all +*.todo+ files given in +paths+.
  #
  # @param [Array] paths an array of path names
  def self.run *paths
    run_before :all
    full_paths = paths.map { |p| File.absolute_path p }
    claimed_paths = claim_paths *full_paths
    claimed_paths.each { |path| run_one path }

    run_after :all
  end

  ##
  # Based on the outcome, return the next task. Returns task named by
  # +task.next_step+ if +outcome+ is non-false; otherwise, the task named by
  # +task.on_fail_step+ is returned. If the the is missing the appropriate next
  # step name (+next+ or +on_fail+), +nil+ is returned.
  #
  # @param [TodoRunner::Task] task last run {TodoRunner::Task}
  # @param [Boolean] outcome whether the task succeeded
  def self.next_step task, outcome
    name = outcome ? task.next_step : task.on_fail_step
    return unless name
    find_task! name
  end

  ##
  # Find the [TodoRunner::Task] specified by +name+. Raises
  # {TodoRunnerException} if +name+ is +nil+ or not task is found.
  #
  # @param [Symbol] name the name of the task
  # @return [TodoRunner::Task]
  def self.find_task! name
    task = self.find_task name
    unless task
      raise TodoRunnerException.new "No task found for name #{name.inspect}"
    end
    task
  end

  ##
  # Find the [TodoRunner::Task] specified by +name+. Raises
  # {TodoRunnerException} if +name+ is +nil+ and +:accept_nil+ is not set.
  #
  # @param [Symbol] name the name of the task
  # @param [Hash] options
  # @option options [Boolean] :accept_nil +true+ if name can be +nil+ [default: +false+]
  # @return [TodoRunner::Task]
  def self.find_task name, options = {}
    return registry[name] if options[:accept_nil]
    raise TodoRunnerException.new 'Task name cannot be nil' unless name
    registry[name]
  end

  ##
  # Mark all this files this runner is processing, changing +paths+' extensions
  # to +.<DATE>-processing+, and returning the list of new path names
  #
  # @param [Array] paths list of paths to rename
  # @return [Array] new path names
  def self.claim_paths *paths
    name = Time.new.strftime('%Y%m%d').to_sym
    paths.map { |path| rename_file path, name, 'processing' }
  end

  protected

  ##
  # Run tasks on +*.todo+ file named by +path+.
  #
  # @param [String] path path to +*.todo+ file
  def self.run_one path
    task   = find_task! @start
    result = run_task task: task, path: path
    task   = next_step task, result.succeeded?

    loop do
      result = run_task task: task, path: result.path
      break if terminal_task? task.name
      task = next_step task, result.outcome
      break if task.nil?
    end

  end

  private

  ##
  # Run single +task+ for +*.todo+ file named by +path+, returning the
  # {TodoRunner::Worker}, which has methods {TodoRunner::Worker#succeeded?} and
  # {TodoRunner::Worker#path}
  #
  # @param [String] path path to +*.todo+ file
  # @return [TodoRunner::Worker]
  def self.run_task task:, path:
    begin
      todo_file = TodoFile.new path, task.name
      worker    = TodoRunner::Worker.new task: task, todo_file: todo_file
      worker.run
      worker
    ensure
      todo_file.close!
    end
  end

  def self.clear
    @registry.select! { |k,v| DEFAULT_TASKS.include? k }
    super
  end
end
