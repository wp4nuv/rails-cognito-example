Rails.application.routes.draw do
  use_doorkeeper
  use_doorkeeper_openid_connect
  # For details on the DSL available within this file, see
  # http://guides.rubyonrails.org/routing.html

  get '/sign_in', as: 'signin', to: 'sessions#signin'
  get '/sign_out', as: 'signout', to: 'sessions#signout'
  get '/sign_up', as: 'signup', to: 'sessions#signup'

  root to: 'home#index'
end
