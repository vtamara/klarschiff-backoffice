# frozen_string_literal: true

module Logging
  extend ActiveSupport::Concern

  module ClassMethods
    attr_accessor :omit_field_log, :omit_field_log_values
  end

  ENUM_ATTRS = %w[].freeze

  included do
    self.omit_field_log = %w[updated_at]
    self.omit_field_log_values = []

    after_create :log_create
    before_update :log_update
    after_destroy :log_destroy
    has_many :log_entries, ->(c) { where(table: c.class.table_name) }, # rubocop:disable Rails/InverseOf
      foreign_key: :subject_id do
      def generate(attr, _action_key, old_value, new_value)
        subject = proxy_association.owner
        old = Logging.convert_value(old_value, attr, subject)
        new = Logging.convert_value(new_value, attr, subject)
        create table: subject.model_name.element, attr: attr, issue_id: Logging.issue_id(subject),
               subject_id: subject.id, subject_name: subject.logging_subject_name,
               action: Logging.generate_action(subject.class, attr, :update, old, new),
               user: Current.user, auth_code: Current.auth_code, old_value: old, new_value: new
      end
    end
  end

  def last_entry
    LogEntry.where(table: model_name.element, subject_id: id).order(created_at: :desc).first
  end

  def log_create
    log_entries.create table: model_name.element, action: Logging.action_text(:create), user: Current.user,
                       auth_code: Current.auth_code, subject_id: id, subject_name: logging_subject_name,
                       issue_id: Logging.issue_id(self)
  end

  def log_update
    changes.each do |attr, (old, new)|
      next if attr.in?(self.class.omit_field_log || self.class.superclass.omit_field_log)
      if ((k, v) = find_reflection_for_attr(attr))
        log_update_for_reflection(k, v, old, new)
      else
        log_update_for_non_reflection(attr, old, new)
      end
    end
  end

  def find_reflection_for_attr(attr)
    self.class.reflections.find { |r| r.last.foreign_key == attr }
  end

  def log_update_for_reflection(attr, reflection, old, new)
    klass = reflection.klass
    log_entries.generate attr, :update, klass.find_by(id: old).to_s, klass.find_by(id: new).to_s
  end

  def log_update_for_non_reflection(attr, old, new)
    old = new = nil if attr.in?(self.class.omit_field_log_values || self.class.superclass.omit_field_log_values)
    log_entries.generate attr, :update, old, new
  end

  def log_destroy
    LogEntry.create table: model_name.element, action: Logging.action_text(:removed), user: Current.user,
                    auth_code: Current.auth_code, subject_id: id, subject_name: logging_subject_name,
                    issue_id: Logging.issue_id(self)
  end

  def log_habtm_add(obj)
    log_assoc "#{obj.logging_subject_name} #{Logging.action_text :added}"
  end

  def log_habtm_remove(obj)
    log_assoc "#{obj.logging_subject_name} #{Logging.action_text :removed}"
  end

  def log_assoc(action)
    return unless id
    log_entries.create table: model_name.element, action: action, user: Current.user, auth_code: Current.auth_code,
                       subject_id: id, subject_name: logging_subject_name, issue_id: Logging.issue_id(self)
  end

  def logging_subject_name
    "#{model_name.human} #{self}"
  end

  def self.issue_id(subject)
    issue = subject.issue if subject.respond_to?(:issue)
    issue = subject if subject.instance_of?(Issue)
    issue&.id
  end

  def self.generate_action(subject_class, attr, action_key, old_value, new_value)
    text = "#{subject_class.human_attribute_name(attr)} #{Logging.action_text(action_key)}"
    text += ": '#{old_value}' →  '#{new_value}'" unless old_value.nil? && new_value.nil?
    text
  end

  def self.action_text(key)
    case key
    when :update then 'geändert'
    when :create then 'angelegt'
    when :added then 'hinzugefügt'
    when :removed then 'entfernt'
    else raise "Unknown action_key #{key}"
    end
  end

  def self.convert_value(value, attr, subject)
    return subject.class.enum_value(value, attr) if attr.in?(ENUM_ATTRS)
    return ActiveSupport::NumberHelper.number_to_delimited(value) if value.is_a? Numeric
    case value
    when false, true then I18n.t(value)
    else value
    end
  end
end
