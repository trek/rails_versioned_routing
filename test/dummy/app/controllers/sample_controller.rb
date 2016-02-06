class SampleController < ApplicationController
  def final_fallback
    render text: 'v0'
  end
end