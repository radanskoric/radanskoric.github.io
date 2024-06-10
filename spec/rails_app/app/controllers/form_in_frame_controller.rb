class FormInFrameController < ApplicationController
  before_action :save_message, except: %i[index]

  def index
  end

  def target_top
    redirect_to action: :index
  end

  def refresh_action
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.action(:refresh, "") }
      format.html { redirect_to :index }
    end
  end

  def visit_control
    redirect_to action: :index, params: { force_reload: true}
  end

  def custom_action
    redirect_path = form_in_frame_path
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.action(:full_page_redirect, redirect_path) }
      format.html { redirect_to redirect_path }
    end
  end

  private

  def save_message
    if params[:message].blank?
      render partial: "error", status: :unprocessable_entity
      return
    end

    session[:form_in_frame] = params[:message]
  end

end
