# frozen_string_literal: true

class IssuesController < ApplicationController
  include Export
  include Index

  before_action :set_tab

  def show
    check_auth(:edit_issue, Issue.find(params[:id]))
    @edit_issue_url = edit_issue_url(params[:id])
    @issues = paginate(results)
    render :index
  end

  def edit
    @issue = Issue.authorized.find(params[:id])
    check_auth(:edit_issue, @issue)
    @issue.responsibility_action = @issue.reviewed_at.blank? ? :recalculation : :accept
    respond_to do |format|
      format.js { prepare_tabs }
      format.html do
        html_response
        render :index
      end
    end
  end

  def new
    @issue = Issue.new
  end

  def update
    @issue = Issue.find(params[:id])
    check_auth(:edit_issue, @issue)
    return render inline: 'location.reload();' if @issue.update(issue_params) && params[:save_and_close].present?
    prepare_tabs
    render :edit
  end

  def create
    check_auth(:create_issue)
    @issue = Issue.new(issue_params.merge(status: :received))
    if @issue.save
      return redirect_to action: :index if params[:save_and_close].present?
      prepare_tabs
      render :edit
    else
      render :new
    end
  end

  def resend_responsibility
    issue = Issue.find(params[:issue_id])
    check_auth :resend_responsibility, issue
    issue.send :notify_group
  end

  def update_address
    issue = Issue.find(params[:id])
    issue.assign_attributes(issue_params)
    issue.send(:update_address_parcel_property_owner)
    respond_to do |format|
      format.json { address_response(issue) }
    end
  end

  private

  def address_response(issue)
    external_coords = I18n.t(
      'issues.external_map.coordinates', x: issue.lon_external&.round, y: issue.lat_external&.round
    )
    json_response = { address: issue.address, parcel: issue.parcel, property_owner: issue.property_owner,
                      external_coords: external_coords }
    render json: json_response, status: :ok
  end

  def prepare_tabs
    @tabs = issue_tabs
    @feedbacks = feedbacks(@issue) if @tab == :feedback
    @log_entries = log_entries(@issue) if @tab == :log_entry
  end

  def issue_tabs
    tabs = %i[master_data responsibility]
    tabs << :job if Current.user.authorized?(:jobs)
    tabs << :feedback if @issue.feedbacks.any?
    tabs + %i[comment abuse_report map photo log_entry]
  end

  def feedbacks(issue)
    issue.feedbacks.order(created_at: :desc).page(params[:page] || 1).per params[:per_page] || 10
  end

  def log_entries(issue)
    issue.all_log_entries.order(created_at: :desc).page(params[:page] || 1).per params[:per_page] || 10
  end

  def issue_params
    return {} if params[:issue].blank?
    params.require(:issue).permit(*permitted_attributes)
  end

  def permitted_attributes
    attributes = [:address, :archived, :author, :category_id, :delegation_id, :description,
                  :description_status, :expected_closure, :group_id, :new_photo, :parcel, :photo_requested,
                  :position, :priority, :property_owner, :responsibility_action, :status, :status_note,
                  { photos_attributes: permitted_photo_attributes }]
    attributes += %i[job_date job_group_id] if Current.user.authorized?(:jobs)
    attributes
  end

  def permitted_photo_attributes
    %i[id status censor_rectangles censor_width censor_height _modification _destroy]
  end

  def set_tab
    @tab = params[:tab]&.to_sym || :master_data
  end
end
