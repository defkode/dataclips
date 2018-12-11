Dataclips::Engine.routes.draw do
  resources :insights, only: [:show] do
    get :data, on: :member
  end
end
