class StoreFrontSwitchesController < ApplicationController
  def create
    store_front = current_user.switchable_store_fronts.find_by(id: params[:store_front_id])
    if store_front
      session[:store_front_id] = store_front.id
      redirect_back fallback_location: "/", notice: "Switched to #{store_front.name}."
    else
      redirect_back fallback_location: "/", alert: "You don't have access to that store front."
    end
  end
end
