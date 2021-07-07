class UsersController < ApplicationController
  layout 'benefits', only: [:profile]

  skip_before_filter :require_user, only: [:login, :password, :register, :login_with_token, :reset_password, :profile]

  before_filter :reset_user_session, only: [:login, :password, :register, :password_reset]

  skip_before_filter :go_to_url_after_login

  def reset_user_session
    session[:user_id] = nil
  end

  def update
    _user.update(params_for(User))

    if params[:user] && params[:user][:password]
      _user.update(password:params[:user][:password])
    end

    flash[:notice] = "Your profile has been updated"

    redirect_to (root_path || :back)
  end

  def register
    @user = User.new(params_for(User))
    @user.password = (params[:user] && params[:user][:password])

    return unless request.post?

    @user.organization = Organization.new
    if @user.save
      session[:user_id] = @user.id
      redirect_to root_path
      return
    end
  end

  def login
    @user = User.new(params_for(User))

    return unless request.post?

    if @user = User.login(params[:user][:email], params[:user][:password])
      session[:user_id] = @user.id

      if session[:url]
        go_to_path = session[:url]
        session[:url] = nil
      else
        go_to_path = root_path
      end


      redirect_to go_to_path
    else
      flash[:notice] = "Unable to login. Please try a different email/password combination."
      @user = User.new(params_for(User))
    end
  end

  def logout
    session.clear
    redirect_to root_path
  end

  def relogin_super_admin
    if session[:super_admin_id]
      if session[:referrer]
        @redirect = session[:referrer]
        session[:referrer] = nil
      elsif @old_user = session[:user_id] && User.find(session[:user_id])
        @redirect = organization_person_path(@old_user.organization, @old_user)
      end

      @user = User.find(session[:super_admin_id])
      if @user
        session[:user_id]= @user.id
        redirect_to (@redirect || root_path)
        return
      end
    end
  end

  def login_with_token
    session[:referrer] = request.referrer

    if _user
      if _user.super_admin?
        session[:super_admin_id] = _user.id
      end
    end

    @user = User.find_by(uuid:params[:user_uuid])

    if @user.email =~ /\.bak/im
      orig_user_email = @user.email.gsub(/\.bak/, '').strip
      if orig_user = User.where(email: orig_user_email).first
       @user = orig_user
      end
     end

    if @user
      session[:user_id] = @user.id
      redirect_to products_path
    else
      flash[:error] = "We were unable to log you in. Please try entering your email and password."
      redirect_to login_path
    end
  end

  def password
    @user = User.new

    return unless request.post?

    if params[:user][:email].present? && @user = User.find_by(email:params[:user][:email])
      @user.delay(priority:0).send_reset_password
      flash[:notice] = "Your link has been emailed to #{@user.email}."
      @user = User.new
    else
      flash[:notice] = "We were unable to find that email. Please try again."
      @user = User.new
    end
  end

  def reset_password
    @user = User.find_by(uuid:params[:user_uuid])

    if @user
      session[:user_id] = @user.id
      redirect_to root_path
    else
      flash[:error] = "We were unable to log you in. Please try entering your email and password."
      redirect_to login_path
    end
  end

end
