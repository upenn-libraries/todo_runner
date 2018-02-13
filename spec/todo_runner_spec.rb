require 'spec_helper'
require 'yaml'

RSpec.describe TodoRunner do

  let(:chocolate_cake_todo) {
    fixture = File.join RSPEC_ROOT, 'fixtures/chocolate_cake.todo'
    tempfile = File.join TMP_DIR, File.basename(fixture)
    FileUtils.cp fixture, tempfile
    tempfile
  }

  let(:carrot_cake_todo) {
    fixture = File.join RSPEC_ROOT, 'fixtures/carrot_cake.todo'
    tempfile = File.join TMP_DIR, File.basename(fixture)
    FileUtils.cp fixture, tempfile
    tempfile
  }

  let(:files_to_delete) { [chocolate_cake_todo, carrot_cake_todo] }

  before(:each) do
    files_to_delete.each do |file|
      path = file.sub /\.[^.]+$/, '.*'
      FileUtils.rm_f path
    end

    TodoRunner.define do

      @counter = 0

      start :mix

      task :mix, on_fail: :STOP, next_step: :bake do
        puts "Hi!"
        @counter += 1
        recipe = YAML.load todo_data
        true
      end

      task :bake, on_fail: :STOP, next_step: :SUCCESS do
        puts "Bye!"
        @counter += 1
        true
      end
    end
  end

  it 'has a version number' do
    expect(TodoRunner::VERSION).not_to be nil
  end

  it 'creates a task proxy' do
    expect(TodoRunner::DefinitionProxy.new).to be_a TodoRunner::DefinitionProxy
  end

  it 'runs a task' do
    expect {
      TodoRunner.registry[:bake].run
    }.to output(/Bye!/).to_stdout
  end

  it 'runs all the tasks' do
    expect{
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
    }.to output(/Hi!\nBye!\nSUCCESS!\nHi!\nBye!\nSUCCESS!/).to_stdout
  end
end
