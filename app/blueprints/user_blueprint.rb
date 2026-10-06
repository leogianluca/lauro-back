class UserBlueprint < Blueprinter::Base
  identifier :id

  fields :email, :name, :role

  field :permissions do |user|
    user.permissions
  end
end
