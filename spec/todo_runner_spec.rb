require "spec_helper"

RSpec.describe TodoRunner do
  it 'has a version number' do
    expect(TodoRunner::VERSION).not_to be nil
  end

  it 'creates a task proxy' do
    expect(TodoRunner::TaskProxy.new).to be_a TodoRunner::TaskProxy
  end

  it 'creates a task' do
    expect {
      TodoRunner.define do
        task :mix, on_fail: :stop, next_step: :bake
        task :bake, on_fail: :stop, next_step: :SUCCESS
      end
      TodoRunner.registry[:mix].call
    }.to output.to_stdout
  end
end
