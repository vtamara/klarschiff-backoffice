# frozen_string_literal: true

class GroupsController < ApplicationController
  include Filter

  def index
    groups = filter(Group.all).order(:short_name)

    respond_to do |format|
      format.html { @groups = groups.page(params[:page] || 1).per(params[:per_page] || 20) }
      format.json { render json: groups }
    end
  end

  def edit
    @group = Group.find(params[:id])
  end

  def new
    @group = Group.new
  end

  def update
    @group = Group.find(params[:id])
    if @group.update(group_params) && params[:save_and_close].present?
      redirect_to action: :index
    else
      render :edit
    end
  end

  def create
    @group = Group.new group_params
    if @group.save
      if params[:save_and_close].present?
        redirect_to action: :index
      else
        render :edit
      end
    else
      render :new
    end
  end

  private

  def group_params
    params.require(:group).permit(:active, :name, :short_name, :kind, :email, :instance_id, :main_user_id, user_ids: [])
  end

  def filter_name_columns
    %i[name short_name]
  end
end
