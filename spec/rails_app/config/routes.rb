Rails.application.routes.draw do
  get 'form_in_frame' => 'form_in_frame#index'
  %i[target_top refresh_action visit_control custom_action].each do |action|
    post "form_in_frame/#{action}" => "form_in_frame##{action}", as: "form_in_frame_#{action}"
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
