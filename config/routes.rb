Dataclips::Engine.routes.draw do
  resources :insights, only: [:show]
end
