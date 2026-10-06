module Api
  module V1
    module Admin
      class UsersController < BaseController
        def index
          authorize User
          users = User.order(created_at: :desc)
          pagination, users = paginate_collection(users)
          render_success(data: UserBlueprint.render_as_hash(users), meta: pagination_meta(pagination))
        end

        def show
          user = User.find(params[:id])
          authorize user
          render_success(data: UserBlueprint.render_as_hash(user))
        end

        def update
          user = User.find(params[:id])
          authorize user
          user.update!(user_params)
          audit!("user.updated", user)
          render_success(data: UserBlueprint.render_as_hash(user))
        end

        def destroy
          user = User.find(params[:id])
          authorize user
          user.destroy!
          audit!("user.deleted", user)
          render_success(data: nil)
        end

        private

        def user_params
          permitted = params.require(:user).permit(:name)
          requested_role = params.dig(:user, :role).to_s
          permitted[:role] = requested_role if User.roles.key?(requested_role)
          permitted
        end
      end
    end
  end
end
