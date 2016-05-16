class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def moodle
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated
      set_flash_message(:notice, :success, :kind => "Moodle") if is_navigational_format?
    elsif 
      redirect_to new_user_registration_url
    end
  end

  def failure
    flash[:error] = I18n.t('omniauth.authentication_error')
    redirect_to login_path
  end
end