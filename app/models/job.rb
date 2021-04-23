# frozen_string_literal: true

class Job < ApplicationRecord
  include Logging

  enum status: { unchecked: 0, checked: 1, not_checkable: 2 }, _prefix: true

  belongs_to :issue
  belongs_to :group, -> { where(kind: Group.kinds[:field_service_team]) }, inverse_of: :jobs

  validates :status, presence: true

  before_validation :set_order, on: :create

  def self.group_by_user_group(job_date)
    Job.where(group: Current.user&.group, date: job_date).group_by { |j| j.group.name }
  end

  def status_color
    return if status == 'not_checkable'
    " text-#{status == 'checked' ? 'success' : 'danger'}"
  end

  private

  def set_order
    self.order = Job.where(group: group, date: date).order(:order).pluck(:order).last.to_i + 1
  end
end
