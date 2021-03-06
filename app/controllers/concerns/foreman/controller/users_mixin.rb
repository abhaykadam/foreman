module Foreman::Controller::UsersMixin
  extend ActiveSupport::Concern

  included do
    before_action :clear_session_locale_on_update, :only => :update
  end

  def resource_scope(options = {})
    super(options).except_hidden
  end

  protected

  def clear_session_locale_on_update
    if params[:user] && editing_self?
      # Remove locale from the session when set to "Browser Locale" and editing self
      session.delete(:locale) if params[:user][:locale].try(:empty?)
    end
  end

  def editing_self?
    @editing_self ||= User.current.editing_self?(params.slice(:controller, :action, :id))
  end

  def update_sub_hostgroups_owners
    return if params[:user]['hostgroup_ids'].empty?
    hostgroup_ids = params[:user]['hostgroup_ids'].reject(&:empty?).map(&:to_i)
    return if hostgroup_ids.empty?

    sub_hg = Hostgroup.where(:id => hostgroup_ids).map(&:subtree).flatten.reject { |hg| hg.user_ids.include?(@user.id) }
    sub_hg.each { |hg| hg.users << @user }
  end

  def set_current_taxonomies(user, options = {})
    session ||= options.fetch(:session, {})
    ['location', 'organization'].each do |taxonomy|
      default_taxonomy = user.send "default_#{taxonomy}"
      if default_taxonomy.present?
        taxonomy.classify.constantize.send 'current=', default_taxonomy
        session["#{taxonomy}_id"] = default_taxonomy.id
      end
    end
  end

  module_function :set_current_taxonomies
end
