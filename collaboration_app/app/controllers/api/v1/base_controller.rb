class Api::V1::BaseController < ApplicationController
  before_action :require_login
  
  protected
  
  def render_error(message, status = :unprocessable_entity)
    render json: { error: message }, status: status
  end
  
  def render_errors(errors, status = :unprocessable_entity)
    render json: { errors: errors }, status: status
  end
  
  def render_success(data = {}, message = nil)
    response = data
    response[:message] = message if message
    render json: response
  end
end