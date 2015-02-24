Dataclips::Engine.routes.draw do
  get "/clips/:clip_id" => "clips#show", as: :clip

  resources :insights
end
