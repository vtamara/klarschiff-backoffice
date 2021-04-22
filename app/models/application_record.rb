# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  before_validation :strip_input_fields

  def self.human_enum_name(enum_name, enum_value)
    I18n.t("enums.#{model_name.i18n_key}.#{enum_name}.#{enum_value}")
  end

  def strip_input_fields
    attributes.each do |name, value|
      self[name] = value.strip if value.respond_to?(:strip) && column_for_attribute(name).type == :text
    end
  end
end
