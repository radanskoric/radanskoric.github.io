require_relative '../../lib/state_machine'

RSpec.describe StateMachine do
  describe 'machine definition support' do
    subject { Class.new(described_class) }

    describe '#add_state' do
      it 'adds the state' do
        expect { subject.add_state(:start) }
          .to change { subject.states.count }.by(1)
      end

      it 'returns the state name back' do
        expect(subject.add_state(:foo)).to eq :foo
      end
    end

    describe '#add_transition' do
      before do
        subject.add_state(:start)
        subject.add_state(:end)
      end

      it 'adds the transition when it connects existing states' do
        expect { subject.add_transition(:do_magic, from: :start, to: :end) }
          .to change { subject.transitions.count }.by(1)
      end

      it 'returns the transition name back' do
        expect(subject.add_transition(:foo, from: :start, to: :end)).to eq :foo
      end

      it 'raises exception when from node is missing' do
        expect { subject.add_transition(:do_magic, from: :foo, to: :end) }
          .to raise_exception StateMachine::InvalidNode
      end

      it 'raises exception when to node is missing' do
        expect { subject.add_transition(:do_magic, from: :start, to: :bar) }
          .to raise_exception StateMachine::InvalidNode
      end
    end
  end

  context 'with a subclass' do
    let(:subclass) do
      Class.new(described_class) do
        add_state :start
        add_state :end
        add_state :dummy

        add_transition :do_stuff, from: :start, to: :end
        add_transition :dance, from: :dummy, to: :end
      end
    end

    subject { subclass.new }

    it 'starts with the first defined state' do
      expect(subject.state).to eq :start
    end

    it 'implements transitions as bang methods' do
      expect { subject.do_stuff! }.to change(subject, :state).from(:start).to(:end)
    end

    it 'does not allow invalid transitions to be performed' do
      expect { subject.dance! }.to raise_exception StateMachine::BadTransition
    end

    context 'with more than one transition with the same name' do
      let(:subclass) do
        Class.new(described_class) do
          add_state :start1
          add_state :start2
          add_state :end

          add_transition :do_stuff, from: :start1, to: :end
          add_transition :do_stuff, from: :start2, to: :end
          add_transition :go_to_start2, from: :start1, to: :start2
        end
      end

      it 'with works on the first instance' do
        expect { subject.do_stuff! }.to change(subject, :state).from(:start1).to(:end)
      end

      it 'with works on the second instance' do\
        subject.go_to_start2!
        expect { subject.do_stuff! }.to change(subject, :state).from(:start2).to(:end)
      end
    end
  end
end
