module Api
  module V1
    class MeController < ApplicationController
      before_action :authenticate_user!

      def show
        render_success(data: UserBlueprint.render_as_hash(current_user))
      end
    end
  end
end
