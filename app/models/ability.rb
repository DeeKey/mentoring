class Ability
  include CanCan::Ability

  def initialize(user)
    if user
      collaborators_ids = user.orphanage ? user.orphanage.users.where.not(id: user.id).pluck(:id) : []

      common_access user if user.has_role?(:employee)

      if user.has_role?(:mentor)
        meetings_ids = user.meetings.pluck(:id)

        common_access user
        can :read, User, id: user.curator_id

        can :manage, Meeting, mentor_id: user.id
        can [:read, :new, :create, :update, :resend], Report, meeting_id: meetings_ids

        can :read, Book, owner_id: user.curator_id
        can :manage, Album, user_id: user.id
        can :manage, Photo, user_id: user.id

        can :read, PublicActivity::Activity, {owner_type: 'User', owner_id: user.curator_id,
                                              trackable_type: 'Meeting', trackable_id: meetings_ids}
        can :read, PublicActivity::Activity, {owner_type: 'User', owner_id: user.curator_id,
                                              trackable_type: 'Report',
                                              trackable_id: Report.where(meeting_id: meetings_ids).map(&:id)}
        can :read, PublicActivity::Activity, {owner_type: 'User', owner_id: user.curator_id,
                                              trackable_type: 'Book'}
        can :read, PublicActivity::Activity, {owner_type: 'User', owner_id: collaborators_ids,
                                              trackable_type: 'Photo'}
      end

      if user.has_role?(:curator)
        subordinates_ids = user.subordinates.with_role(:mentor).pluck(:id)

        common_access user
        can :read, User, curator_id: user.id

        can [:read, :reject, :reject_report, :approve_report], Meeting, mentor_id: subordinates_ids
        can [:read, :reject, :approve], Report, meeting: { mentor_id: subordinates_ids }

        can :read, Book
        can :manage, Book, owner_id: user.id
        can :manage, Album, user_id: user.id
        can :manage, Photo, user_id: user.id

        can :read, PublicActivity::Activity, {owner_type: 'User', owner_id: subordinates_ids,
                                              trackable_type: 'Meeting'}
        can :read, PublicActivity::Activity, {owner_type: 'User', owner_id: subordinates_ids,
                                              trackable_type: 'Report'}
        can :read, PublicActivity::Activity, {owner_type: 'User', owner_id: collaborators_ids,
                                              trackable_type: 'Book'}
        can :read, PublicActivity::Activity, {owner_type: 'User', owner_id: collaborators_ids,
                                              trackable_type: 'Photo'}
      end

      can :manage, :all if user.has_role?(:admin)
    end
  end

  private
    def common_access(user)
      can [:read, :create], Comment
      can :read, Album
      can :read, Photo
      can :read, User, orphanage_id: user.orphanage_id unless user.orphanage_id == nil
      can :read, user
      can :update, user
    end
end
