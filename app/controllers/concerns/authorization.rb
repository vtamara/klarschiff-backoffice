# frozen_string_literal: true

module Authorization
  extend ActiveSupport::Concern

  included do
    before_action :authenticate

    helper_method :authorized?, :authorized_for_administration?
  end

  private

  def authorized?(action, object = nil, user = Current.user)
    user&.authorized?(action, object)
  end

  def authenticate
    Current.login = session[:user_login]
    return redirect_to(new_logins_path) unless Current.login
    login = session[:login].presence || Current.login
    if (Current.user = User.active.find_by(User.arel_table[:login].matches(login)))
      logger_current_user login
    else
      redirect_to new_logins_path
    end
  end

  def logger_current_user(login)
    msg = "Username: #{Current.login}"
    msg += " as #{login}" unless login.casecmp(Current.login.downcase).zero?
    logger.info msg
  end
end
