# frozen_string_literal: true

module UserLogin
  extend ActiveSupport::Concern

  private

  def login(group_kind: nil)
    user = login_user(@credentials[:login], group_kind: group_kind)
    if user&.ldap.present? && Ldap.login(user.ldap, @credentials[:password]) ||
       user&.authenticate(@credentials[:password])
      return login_success(user)
    end
    login_error 'Login oder Passwort sind nicht korrekt'
  end

  def login_error(error)
    @error = error
    logger.info error
    render :new
  end

  def login_success(user)
    session[:user_login] = user.login
    redirect_to root_url
  end

  def find_users(login, group_kind: nil)
    user_condition(Citysdk::User.active, login: login, group_kind: group_kind)
  end

  def login_user(login, group_kind: nil)
    user_condition(User.active, login: login, group_kind: group_kind).first
  end

  def user_condition(users, login:, group_kind:)
    users = users.joins(:groups).where(group: { kind: group_kind }) if group_kind
    users.where(User.arel_table[:login].matches(login).or(User.arel_table[:email].matches(login)))
  end

  def check_credentials
    @credentials = params.permit(:login, :password)
    @credentials = params.require(:login).permit(:login, :password) if @credentials[:password].blank?
    return if @credentials.values.all?(&:present?)
    login_error 'Login und Passwort müssen angegeben werden'
  end
end
