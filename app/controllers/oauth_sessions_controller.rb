class OAuthSessionsController < ApplicationController
  def create
    session[:oauth_response] = request.env["omniauth.auth"]
    render :text => "Authenticated, please close tab to return to ManageIQ."
  end
end
