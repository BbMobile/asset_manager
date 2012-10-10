class Ability
  include CanCan::Ability
  include GroupHelper

  def initialize(user,asset_type_id = nil)
    user ||= User.new

    if user.is_admin
      can :admin
    end

    if asset_type_id != nil
      securities = SecurityScheme.where(:asset_type_id => BSON::ObjectId.from_string(asset_type_id)).all

      if securities.size == 0
        can :manage, Asset, :asset_type_id => asset_type_id
      else
        securities.each do |security|
          security.create_restrictions[:users].each do |privilegedUsers|
            privilegedUsers.each do |privilegedUser|
              if privilegedUser == user.id.to_s
                can :create, Asset, :asset_type_id => security.asset_type_id.to_s
              end
            end
          end
          security.create_restrictions[:groups].each do |privilegedGroups|
            privilegedGroups.each do |privilegedGroup|
              if isUserMemberOf(user,privilegedGroup)
                can :create, Asset, :asset_type_id => security.asset_type_id.to_s
              end
            end
          end

          security.edit_restrictions[:users].each do |privilegedUsers|
            privilegedUsers.each do |privilegedUser|
              if privilegedUser == user.id.to_s
                can :update, Asset, :asset_type_id => security.asset_type_id.to_s
              end
            end
          end
          security.edit_restrictions[:groups].each do |privilegedGroups|
            privilegedGroups.each do |privilegedGroup|
              if isUserMemberOf(user,privilegedGroup)
                can :update, Asset, :asset_type_id => security.asset_type_id.to_s
              end
            end
          end

          security.view_restrictions[:users].each do |privilegedUsers|
            privilegedUsers.each do |privilegedUser|
              if privilegedUser == user.id.to_s
                can :read, Asset, :asset_type_id => security.asset_type_id.to_s
              end
            end
          end
          security.view_restrictions[:groups].each do |privilegedGroups|
            privilegedGroups.each do |privilegedGroup|
              if isUserMemberOf(user,privilegedGroup)
                can :read, Asset, :asset_type_id => security.asset_type_id.to_s
              end
            end
          end

          security.delete_restrictions[:users].each do |privilegedUsers|
            privilegedUsers.each do |privilegedUser|
              if privilegedUser == user.id.to_s
                can :destroy, Asset, :asset_type_id => security.asset_type_id.to_s
              end
            end
          end
          security.delete_restrictions[:groups].each do |privilegedGroups|
            privilegedGroups.each do |privilegedGroup|
              if isUserMemberOf(user,privilegedGroup)
                can :destroy, Asset, :asset_type_id => security.asset_type_id.to_s
              end
            end
          end

        end
      end
    end
  end

end
