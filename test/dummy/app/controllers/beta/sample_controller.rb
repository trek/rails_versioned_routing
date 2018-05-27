module Beta
  class SampleController < ApplicationController
    def a_path_overridden_from_v1
      render text: 'beta'
    end

    def a_path_only_in_beta
      render text: 'beta'
    end
  end
end
