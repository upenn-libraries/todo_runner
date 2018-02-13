require 'tempfile'
require 'todo_runner/version'
require 'todo_runner/task'
require 'todo_runner/definition_proxy'
require 'todo_runner/worker'

module TodoRunner
  # TODO: Add :CONTINUE behavior
  # TODO: Add #run_dir method
  # TODO: ?? Add before, after callbacks before|after(:each|:all)
  # TODO: Decide how to handle errors and falling back to errors
  # TODO: Logging????

  DEFAULT_TASKS = %i{ STOP SUCCESS FAIL CONTINUE }.freeze
  TERMINAL_TASKS = %i{ STOP SUCCESS FAIL }

  @registry  = {}
  @start     = nil
  @todo_data = nil

  @registry[:STOP] = Task.new :STOP do
    puts 'STOPPING'
  end

  @registry[:SUCCESS] = Task.new :SUCCESS do
    puts 'SUCCESS!'
  end

  @registry[:FAIL] = Task.new :FAIL do
    puts 'FAILED!'
  end

  @registry[:CONTINUE] = Task.new :CONTINUE do
    puts 'CONTINUING!'
  end

  @registry[:ERROR] = Task.new :ERROR do
    puts 'ERROR!'
  end

  def self.define &block
    definition_proxy = DefinitionProxy.new
    definition_proxy.instance_eval &block
  end

  def self.todo_data
    @todo_data
  end

  def self.registry
    @registry
  end

  def self.start= name
    @start = name
  end

  def self.start
    @start
  end

  def self.terminal_task? name
    return true if name.nil?
    TERMINAL_TASKS.include? name
  end

  def self.run *files
    files.each do |file|
      run_one file
    end
  end

  def self.next_step task, outcome
    name = outcome ? task.next_step : task.on_fail_step
    return unless name
    raise "No task found named #{name.inspect}" unless registry.include? name
    registry[name]
  end

  protected

  def self.run_one file
    @current_file = file

    task    = registry[@start]
    outcome = run_task task
    task    = next_step task, outcome

    loop do
      outcome = run_task task
      break if terminal_task? task.name
      task = next_step task, outcome
      break if task.nil?
    end
  end

  def self.set_data task_name
    @todo_data.close! if @todo_data
    @todo_data = Tempfile.new task_name.to_s
    open(@current_file, 'r').each {|line| @todo_data.puts line.strip}
    @todo_data.rewind
  end

  def self.current_file
    @current_file
  end

  def self.current_file= file
    @current_file = file
  end

  private

  def self.run_task task
    worker = TodoRunner::Worker.new task, current_file
    set_data task.name
    worker.run
    self.current_file = worker.file
    worker.outcome
  end
end
