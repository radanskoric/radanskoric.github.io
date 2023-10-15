
class StateMachine
  class Builder

    class StateProxy
      attr_reader :state_name

      def initialize(state_machine, state_name)
        @state_machine = state_machine
        @state_name = state_name
      end

      def leads_to(other_state, with:)
        @state_machine.add_transition(
          with,
          from: @state_name,
          to: other_state.state_name
        )
      end
    end

    class GroupProxy
      def initialize(state_machine, states)
        @state_machine = state_machine
        @states = states
      end

      def leads_to(other_state, with:)
        @states.each do |state|
          @state_machine.add_transition(
            with,
            from: state.state_name,
            to: other_state.state_name
          )
        end
      end
    end

    attr_reader :states

    def initialize(state_machine)
      @state_machine = state_machine
      @states = {}
    end

    def group(group_name, &block)
      sub_machine = self.class.new(@state_machine)
      sub_machine.instance_exec(&block)
      @states.merge! sub_machine.states
      @states[group_name] ||= GroupProxy.new(
        @state_machine,
        sub_machine.states.values
      )
    end

    def method_missing(state_name)
      @states[state_name] ||= StateProxy.new(
        @state_machine,
        @state_machine.add_state(state_name)
      )
    end
  end
end
