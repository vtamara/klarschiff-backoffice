# frozen_string_literal: true

class Job < ApplicationRecord
  include Logging

  belongs_to :issue
  belongs_to :group, -> { where(kind: Group.kinds[:field_service_team]) }, inverse_of: :jobs

  enum status: { checked: 0, unchecked: 1, not_checkable: 2 }, _prefix: true

  validates :status, presence: true

  before_validation :set_order, on: :create

  private

  def set_order
    self.order = Job.where(group: group, date: date).order(:order).pluck(:order).last.to_i + 1
  end
end
