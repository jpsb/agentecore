class AccountsController < ApplicationController
  skip_before_filter :login_required, :except => :logout
  skip_after_filter :store_location
  layout 'plain'



  def login
    redirect_back_or_default(home_path) and return if @u
    @user = User.new
    return unless request.post?


    #plays double duty login/forgot (due to the ajax nature of the login/forgot form)
    if params[:user][:email] && params[:user][:email].size > 0
      u = Profile.find_by_email(params[:user][:email]).user rescue nil
      flash.now[:error] = t(:could_not_find_email) and return if u.nil?

      @pass = u.forgot_password #must be @ variable for function tests
      AccountMailer.deliver_forgot_password(u.profile.email, u.f, u.login, @pass)
      flash.now[:notice] = t(:password_mailed_to_you)
    else
      params[:login] ||= params[:user][:login] if params[:user]
      params[:password] ||= params[:user][:password] if params[:user]
      self.user = User.authenticate(params[:login], params[:password])
      if @u
        remember_me if params[:user][:remember_me] == "1"
        flash[:notice] = t(:hello_login, :nome => @u.f)
        redirect_back_or_default profile_url(@u.profile)
      else
        flash.now[:error] = t(:error_login)
      end
    end
  end





  def logout
    cookies[:auth_token] = {:expires => Time.now-1.day, :value => "" }
    session[:user] = nil
    session[:return_to] = nil
    flash[:notice] = t(:you_logged_out)
    redirect_to '/'
  end






  def signup
    redirect_back_or_default(home_path) and return if not @u or not @u.is_admin?
    @user = User.new
    return unless request.post?


    u = User.new
    u.terms_of_service = params[:user][:terms_of_service]
    u.login = params[:user][:login]
    u.password = params[:user][:password]
    u.password_confirmation = params[:user][:password_confirmation]
    u.email = params[:user][:email]
    u.less_value_for_text_input = params[:user][:less_value_for_text_input]

    @u = u
    if u.save
      #self.user = u


      remember_me if params[:remember_me] == "1"
      flash[:notice] = t(:thanks_signing_up)
      #AuthMailer.deliver_registration(:subject=>t(:new_registration, :app => SITE_NAME), :body => "#{t(:username_label)} = '#{u.login}', email = '#{u.profile.email}'", :recipients=>REGISTRATION_RECIPIENTS)
      #AuthMailer.deliver_registration(:subject=>t(:new_registration, :app => SITE_NAME), :body => "#{t(:username_label)} = '#{@u.login}', email = '#{@u.profile.email}'", :recipients=>REGISTRATION_RECIPIENTS)
      #redirect_to profile_url(@u.profile) and return
      redirect_to admin_users_path() and return
    else
      @user = @u
      params[:user][:password] = params[:user][:password_confirmation] = ''
      flash.now[:error] = @u.errors
      self.user = u# if RAILS_ENV == 'test'
    end
  end









protected

  def remember_me
    self.user.remember_me
    cookies[:auth_token] = {
      :value => self.user.remember_token ,
      :expires => self.user.remember_token_expires_at
    }
  end


  def allow_to
    super :all, :all=>true
  end

end








class AuthMailer < ActionMailer::Base
  def registration(options)
    self.generic_mailer(options)
  end
end

