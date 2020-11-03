# frozen_string_literal: true

class IssuesController < ApplicationController
  include Filter

  before_action :set_tab

  def index
    @issues = filter(Issue.all).order(created_at: :desc).page(params[:page] || 1).per(params[:per_page] || 20)
  end

  def edit
    @issue = Issue.find(params[:id])
    @issue.responsibility_action = @issue.reviewed_at.blank? ? :recalculation : :accept
    @log_entries = log_entries(@issue) if @tab == :log_entry
  end

  def new
    @issue = Issue.new
  end

  def update
    @issue = Issue.find(params[:id])
    if @issue.update(issue_params) && params[:save_and_close].present?
      redirect_to action: :index
    else
      @log_entries = log_entries(@issue) if @tab == :log_entry
      render :edit
    end
  end

  def create
    @issue = Issue.new(issue_params.merge(status: :received))
    if @issue.save
      return redirect_to action: :index if params[:save_and_close].present?
      render :edit
    else
      render :new
    end
  end

  private

  def log_entries(issue)
    issue.all_log_entries.order(created_at: :desc).page(params[:page] || 1).per params[:per_page] || 20
  end

  def issue_params
    return {} if params[:issue].blank?
    params.require(:issue).permit(:address, :archived, :author, :category_id, :delegation_id, :description,
      :description_status, :expected_closure, :job_date, :job_group_id, :new_photo, :parcel, :photo_requested,
      :position, :priority, :property_owner, :responsibility_action, :responsibility_id, :status, :status_note,
      photos_attributes: %i[id status censor_rectangles censor_width censor_height _modification _destroy])
  end

  def set_tab
    @tab = params[:tab]&.to_sym || :master_data
  end
end
