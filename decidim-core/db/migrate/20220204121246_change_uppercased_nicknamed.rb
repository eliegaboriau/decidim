# frozen_string_literal: true

class ChangeUppercasedNicknamed < ActiveRecord::Migration[6.0]
  def up
    # list of users already changed in the process
    has_changed = []
    Decidim::User.find_each do |user|
      next if has_changed.include? user
      # if already downcased, don't care
      next if user.nickname.downcase == user.nickname

      Decidim::User.where("nickname ILIKE ?", user.nickname.downcase).order(:created_at).each_with_index do |similar_user, index|
        next if has_changed.include? similar_user
        next if user == similar_user

        # change his nickname to the lowercased one with -1 if it's the first, -2 if it's the second etc
        transaction do
          Decidim::EventsManager.publish({
                                           event: "decidim.events.nickname_event",
                                           event_class: Decidim::ChangeNicknameEvent,
                                           affected_users: [similar_user],
                                           resource: similar_user,
                                           extra: {
                                             old_nickname: similar_user.nickname,
                                             new_nickname: "#{similar_user.nickname.downcase}-#{index + 1}"
                                           }
                                         })
          similar_user.update!(nickname: "#{similar_user.nickname.downcase}-#{index + 1}")
          has_changed.append(similar_user)
        end
      end

      transaction do
        Decidim::EventsManager.publish({
                                         event: "decidim.events.nickname_event",
                                         event_class: Decidim::ChangeNicknameEvent,
                                         affected_users: [user],
                                         resource: user,
                                         extra: {
                                           old_nickname: user.nickname,
                                           new_nickname: user.nickname.downcase
                                         }
                                       })
        user.update!(nickname: user.nickname.downcase)
        has_changed.append(user)
      end
    end
  end
end
