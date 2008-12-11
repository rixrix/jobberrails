class SessionsController < ApplicationController
  layout 'admin'
  
  def new
    if session[:admin]
      redirect_to admin_url
    end
  end
  
  def create
    admin = Admin.authenticate(params[:login], params[:password])
    if admin
      session[:admin] = admin
      flash[:notice] = "You are logged as #{admin.login}"
      redirect_to admin_url
    else
      session[:admin] = admin
      flash[:error] = "Invalid login or password!"
      render :action => "new"
    end
  end
  
  def destroy
    reset_session
    flash[:notice] = "You've been logged out."
    redirect_to login_url
  end

  # semi-authenticated login for job poster
  def fake_login
    if params[:path].is_a? Array
      # login/:token/*path
      redirect_to "/#{params[:path].join('/')}/#{params[:token]}"
    else
      redirect_to login_url
    end
    redirect_to login_url
  end
end
