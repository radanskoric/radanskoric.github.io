require_relative 'state_machine'

class DemoStateMachine < StateMachine
  define_machine do
    group :creative_process do
      no_idea.leads_to idea, with: :get_inspired
      idea.leads_to working, with: :get_motivated
      idea.leads_to panic, with: :procrastinate
    end
    working.leads_to success, with: :just_do_it
    panic.leads_to success, with: :crunch_it

    creative_process.leads_to failure, with: :give_up
  end
end
