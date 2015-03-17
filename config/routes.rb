Dataclips::Engine.routes.draw do
  if Rails.env.development?
    get "/clips/:clip_id" => "clips#show", as: :clip
  end

  resources :insights do
    get :export, on: :member
  end
end
