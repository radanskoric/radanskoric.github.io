require_relative '../../lib/demo_state_machine'

RSpec.describe DemoStateMachine do
  it 'outputs to a file' do
    described_class.to_png
  end
end
