require 'spec_helper'
require 'yaml'

RSpec.describe TodoRunner do

  let(:chocolate_cake_todo) {
    fixture  = File.join RSPEC_ROOT, 'fixtures/chocolate_cake.todo'
    tempfile = File.join TMP_DIR, File.basename(fixture)
    FileUtils.cp fixture, tempfile
    tempfile
  }

  let(:chocolate_pie_todo) {
    fixture  = File.join RSPEC_ROOT, 'fixtures/chocolate_pie.todo'
    tempfile = File.join TMP_DIR, File.basename(fixture)
    FileUtils.cp fixture, tempfile
    tempfile
  }

  let(:carrot_cake_todo) {
    fixture  = File.join RSPEC_ROOT, 'fixtures/carrot_cake.todo'
    tempfile = File.join TMP_DIR, File.basename(fixture)
    FileUtils.cp fixture, tempfile
    tempfile
  }

  let(:completion_file) {
    File.join TMP_DIR, "completion.txt"
  }

  let(:files_to_delete) {
    [chocolate_cake_todo, carrot_cake_todo, chocolate_pie_todo, completion_file]
  }

  # From a comment on this gist: https://gist.github.com/moertel/11091573
  def suppress_output
    original_stdout, original_stderr = $stdout.clone, $stderr.clone
    $stderr.reopen File.new('/dev/null', 'w')
    $stdout.reopen File.new('/dev/null', 'w')
    yield
  ensure
    $stdout.reopen original_stdout
    $stderr.reopen original_stderr
  end

  def cleanup files
    files_to_delete.each do |file|
      path = file.sub /\.[^.]+$/, '.*'
      FileUtils.rm_f path if File.exist? path
    end
    FileUtils.rm completion_file if File.exist? completion_file
  end

  context 'passing tasks' do
    before(:each) do
      cleanup files_to_delete

      @cwd = Dir.pwd

      TodoRunner.define do

        @counter = 0

        start :mix

        task :mix, on_fail: :STOP, next_step: :bake do |todo_file|
          puts "Hi!"
          @counter += 1
          recipe   = YAML.load todo_file
          Dir.chdir '/'
          true
        end

        task :bake, on_fail: :STOP, next_step: :SUCCESS do
          puts "Bye!"
          @counter += 1
          true
        end

        after :all do
          puts "After all!"
        end
      end # TodoRunner.define

    end

    after(:each) do
      Dir.chdir @cwd
    end

    it 'has a version number' do
      expect(TodoRunner::VERSION).not_to be nil
    end

    it 'creates a task proxy' do
      expect(TodoRunner::DefinitionProxy.new).to be_a TodoRunner::DefinitionProxy
    end

    it 'runs a task' do
      expect {
        TodoRunner.registry[:bake].run open chocolate_cake_todo
      }.to output(/Bye!/).to_stdout
    end

    it 'runs all the tasks' do
      expect {
        TodoRunner.run chocolate_cake_todo
      }.to output(/Hi!\nBye!\nSUCCESS!/).to_stdout
    end

    it 'runs all the tasks and succeeds' do
      expect {
        TodoRunner.run chocolate_cake_todo, carrot_cake_todo
      }.to output(/Hi!\nBye!\nSUCCESS!/).to_stdout
      expect(File.exist? File.join(TMP_DIR, 'chocolate_cake.SUCCESS')).to be_truthy
    end

    it 'has a start task' do
      expect(TodoRunner.start).to eq :mix
    end

    it 'runs multiple tasks' do
      expect {
        TodoRunner.run chocolate_cake_todo, carrot_cake_todo
      }.to output(/Hi!\nBye!\nSUCCESS!\nHi!\nBye!\nSUCCESS!\nAfter all!\n$/).to_stdout
    end
  end

  context 'failing tasks' do
    before :each do
      cleanup files_to_delete

      TodoRunner.define do

        @counter = 0

        start :mix

        task :mix, on_fail: :FAIL, next_step: :bake do |todo_file|
          puts "Hi!"
          @counter += 1
          recipe   = YAML.load todo_file
          false
        end

        task :bake, on_fail: :FAIL, next_step: :SUCCESS do
          puts "Bye!"
          @counter += 1
          true
        end
      end # TodoRunner.define
    end

    it 'handles failure' do
      expect {
        TodoRunner.run chocolate_cake_todo, carrot_cake_todo
      }.to output(/Hi!\nFAILED!\nHi!\nFAILED!/).to_stdout
    end
  end

  context 'error handling' do
    before :each do
      cleanup files_to_delete

      COMPLETION_FILE = completion_file

      TodoRunner.define do

        def log_complete todo_file
          File.open(COMPLETION_FILE, 'a') { |f| f.puts todo_file.todo_path }
        end

        @counter = 0

        start :mix

        task :mix, on_fail: :FAIL, next_step: :bake do |todo_file|
          puts "Hi!"
          @counter += 1
          recipe   = YAML.load todo_file
          # chocolate_pie_todo recipe should cause a NoMethodError here,
          # as the top level key is 'Pie', not 'Cake'
          recipe['Cake']['Name']
          true
        end

        task :bake, on_fail: :FAIL, next_step: :log_complete do |todo_file|
          @counter += 1
          true
        end

        task :log_complete, on_fail: :FAIL, next_step: :SUCCESS do |todo_file|
          YAML.load todo_file
          log_complete todo_file
          true
        end

      end # TodoRunner.define
    end

    it 'persists files even when an error is raised' do
      # Force an error, then make sure the COMPLETION_FILE exists and has the
      # expected number of lines.
      expect {
        suppress_output {
          TodoRunner.run chocolate_cake_todo, carrot_cake_todo, chocolate_pie_todo
        }
      }.to raise_error NoMethodError
      expect(File.exist? COMPLETION_FILE).to be_truthy
      expect(File.readlines(COMPLETION_FILE).size).to eq 2
    end
  end
end
