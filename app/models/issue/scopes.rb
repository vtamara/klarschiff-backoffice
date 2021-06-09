# frozen_string_literal: true

class Issue
  module Scopes
    extend ActiveSupport::Concern

    included do
      scope :not_archived, -> { where(archived_at: nil) }
      scope :status_open, -> { where(status: %w[received reviewed in_process]) }
      scope :status_solved, -> { where(status: %w[duplicate not_solvable closed]) }
    end

    class_methods do # rubocop:disable Metrics/BlockLength
      def authorized(user = Current.user)
        return all if user&.role_admin?
        authorized_group_ids = authorized_group_ids(user)
        authorized_by_areas_for(authorized_group_ids)
          .where(Issue.arel_table[:group_id].in(authorized_group_ids)
            .or(Issue.arel_table[:delegation_id].in(authorized_group_ids)))
          .authorized_by_user_districts
      end

      def by_kind(kind)
        includes(category: :main_category).where(main_category: { kind: kind })
      end

      def not_approved
        includes(:photos).where(
          description_status: %i[internal deleted], photo: { status: %i[internal deleted] }
        )
      end

      def ideas_without_min_supporters
        by_kind(0).having Supporter.arel_table[:id].count.lt(Settings::Vote.min_requirement)
      end

      def ideas_with_min_supporters
        by_kind(0).having Supporter.arel_table[:id].count.gteq(Settings::Vote.min_requirement)
      end

      def authorized_by_user_districts(user = Current.user)
        return all if user.blank? || user.districts.blank?
        where <<~SQL.squish, user.district_ids
          ST_Within("position", (
            SELECT ST_Multi(ST_CollectionExtract(ST_Polygonize(ST_Boundary("area")), 3))
            FROM #{District.quoted_table_name}
            WHERE "id" IN (?)
          ))
        SQL
      end

      def authorized_by_areas_for(group_ids)
        reference_ids = Group.where(id: group_ids).pluck(:reference_id)
        return none if reference_ids.blank?
        where <<~SQL.squish, reference_ids, reference_ids
          ST_Within("position", (
            SELECT ST_Multi(ST_CollectionExtract(ST_Polygonize(ST_Boundary("area")), 3))
            FROM #{County.quoted_table_name}
            WHERE "id" IN (?)
          )) OR ST_Within("position", (
            SELECT ST_Multi(ST_CollectionExtract(ST_Polygonize(ST_Boundary("area")), 3))
            FROM #{Authority.quoted_table_name}
            WHERE "id" IN (?)
          ))
        SQL
      end

      private

      def authorized_group_ids(user = Current.user)
        return user.group_ids unless user&.role_regional_admin?
        user.groups.map { |gr| Group.where(type: gr.type, reference_id: gr.reference_id) }.flatten.map(&:id)
      end
    end
  end
end
