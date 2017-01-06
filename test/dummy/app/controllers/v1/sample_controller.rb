module V1
  class SampleController < ApplicationController
    def a_path_overridden_from_v1
      render text: 'v1'
    end

    def another_path_in_v1
      render text: 'v1'
    end

    def a_path_in_v1_deprecated
      render text: 'v1'
    end
  end
end