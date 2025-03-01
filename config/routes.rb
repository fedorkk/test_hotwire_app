Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  root "pages#article"

  get :article, to: "pages#article"

  get :turbo_frames, to: "pages#turbo_frames"
  get :turbo_frame_change, to: "pages#turbo_frame_change"

  get :init_turbo_streams, to: "turbo_streams#init"
  get :turbo_streams_call, to: "turbo_streams#call"

  resources :addresses, only: [:new, :create] do
    collection do
      get :country_change
      get :city_change
    end
  end
end
