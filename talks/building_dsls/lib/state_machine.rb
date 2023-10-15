require 'graphviz'
require 'set'

require_relative 'state_machine/builder'

# Implementation of a generic state machine class
class StateMachine
  class InvalidNode < StandardError; end
  class BadTransition < StandardError; end

  attr_reader :state

  def initialize
    @state = self.class.states.first
  end

  class << self

    def define_machine(&block)
      Builder.new(self).instance_exec(&block)
    end

    def add_state(state_name)
      states << state_name
      state_name
    end

    def add_transition(transition_name, from:, to:)
      raise InvalidNode unless states.include?(from) && states.include?(to)

      define_transition_method(transition_name)

      transitions << {
        name: transition_name,
        from: from,
        to: to
      }

      transition_name
    end

    def states
      @states ||= []
    end

    def transitions
      @transitions ||= []
    end

    def to_png(file = 'state_machine.png')
      graph = GraphViz.new(:G, type: :digraph)

      graphical_nodes = states.each_with_object({}) do |state, memo|
        memo[state] = graph.add_nodes(state.to_s)
      end

      transitions.each do |transition|
        graph.add_edges(
          graphical_nodes[transition[:from]],
          graphical_nodes[transition[:to]],
          label: transition[:name]
        )
      end

      graph.output(png: file)
    end

    private

    def define_transition_method(transition_name)
      method_name = "#{transition_name}!"
      return if method_defined? method_name

      define_method method_name do
        good_transition = self.class.transitions.find do |transition|
          transition[:name] == transition_name &&
            transition[:from] == @state
        end

        raise BadTransition, transition_name unless good_transition
        @state = good_transition[:to]
      end
    end
  end
end
