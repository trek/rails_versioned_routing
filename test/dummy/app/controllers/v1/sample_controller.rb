module V1
  class SampleController < ApplicationController
    def a_path_overridden_from_v1
      render text: 'v1'
    end
  end
end