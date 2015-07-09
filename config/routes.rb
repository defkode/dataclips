Dataclips::Engine.routes.draw do
  resources :insights do
    get :export, on: :member
  end
end
