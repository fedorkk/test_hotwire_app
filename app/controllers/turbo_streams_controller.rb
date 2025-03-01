class TurboStreamsController < ApplicationController
  def call
    @old_paragraph = params[:old_paragraph]
    @new_paragraph = params[:new_paragraph].to_i || 1
    @log = %(Paragraph #{@new_paragraph} is openned#{@old_paragraph ? ", paragrahp #{@old_paragraph} is closed" : nil})

    respond_to do |format|
      format.turbo_stream {  }
    end
  end
end
