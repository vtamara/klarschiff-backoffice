# frozen_string_literal: true

require 'test_helper'

class GroupTest < ActiveSupport::TestCase
  test 'validate no_associated_categories' do
    group = group(:one)
    assert_valid group
    group.active = false
    assert_not group.valid?
    assert_equal [{ error: :associated_categories }], group.errors.details[:base]
  end

  test 'deactivate group without associated categories' do
    group = group(:external)
    assert_valid group
    assert group.update(active: false)
    assert_not group.reload.active
  end

  test 'authorized scope' do
    assert_equal Group.ids, Group.authorized(user(:admin)).ids
    assert_empty Group.authorized(user(:editor))
    user = user(:regional_admin)
    groups = user.groups.active.distinct.pluck(:type, :reference_id)
      .map { |(t, r)| Group.where type: t, reference_id: r }.inject(:or)
    assert_equal groups.ids, Group.authorized(user).ids
  end
end
