require 'spec_helper'

RSpec.describe TodoRunner do

  let(:chocolate_cake_todo) {
    fixture = File.join RSPEC_ROOT, 'fixtures/chocolate_cake.todo'
    tempfile = File.join TMP_DIR, File.basename(fixture)
    FileUtils.cp fixture, tempfile
    tempfile
  }

  before(:each) do
    TodoRunner.define do

      start :mix

      task :mix, on_fail: :STOP, next_step: :bake do
        puts "Hi!"
        true
      end
      task :bake, on_fail: :STOP, next_step: :SUCCESS do
        puts "Bye!"
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
    # TodoRunner.run chocolate_cake_todo
    expect{
      TodoRunner.run chocolate_cake_todo
    }.to output(/Hi!\nBye!\nSUCCESS!/).to_stdout
  end

  it 'has a start task' do
    expect(TodoRunner.start).to eq :mix
  end
end
