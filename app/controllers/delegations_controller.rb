# frozen_string_literal: true

class DelegationsController < ApplicationController
  include Export

  before_action { check_auth :manage_delegations }
  before_action :set_tab

  def index
    @status = params[:status].to_i
    @issues = issues
    respond_to do |format|
      format.html { html_response }
      format.xlsx { xlsx_export }
    end
  end

  def edit
    @issue = Issue.find(params[:id])
  end

  def update
    @issue = Issue.find(params[:id])
    return reject if params[:reject].present?
    if @issue.update(issue_params) && params[:save_and_close].present?
      redirect_to action: :index
    else
      render :edit
    end
  end

  private

  def issues
    issues = Issue.includes(category: %i[main_category sub_category]).not_archived.where.not(delegation_id: nil)
      .order(created_at: :desc)
    return issues.status_in_process if @status.zero?
    issues.where(status: %i[duplicate not_solvable closed])
  end

  def html_response
    @issues = paginate_issues
    return render :map if params[:show_map] == 'true'
  end

  def reject
    @issue.update(delegation_id: nil)
    redirect_to action: :index
  end

  def set_tab
    @tab = params[:tab]&.to_sym || :master_data
  end

  def issue_params
    return {} if params[:issue].blank?
    params.require(:issue).permit(:status, :status_note)
  end

  def paginate_issues
    @issues.page(params[:page] || 1).per(params[:per_page] || 20)
  end
end
