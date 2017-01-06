module V2
  class SampleController < ApplicationController
    def a_path_in_v2
      render text: 'v2'
    end

    def a_path_overridden_from_v1
      render text: 'v2'
    end

    def a_path_in_v1_deprecated
      render text: 'v2'
    end
  end
end
