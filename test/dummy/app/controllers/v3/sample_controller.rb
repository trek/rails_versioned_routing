module V3
  class SampleController < ApplicationController
    def a_path_only_in_v3
      render text: 'v3'
    end

    def posted_a_path_only_in_v3
      render text: 'v3'
    end
  end
end