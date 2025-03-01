class PagesController < ApplicationController
  def article; end

  def turbo_frame_change
    current_paragraph = params[:paragraph].to_i || 1

    render partial: "paragraph_#{current_paragraph}"
  end
end
