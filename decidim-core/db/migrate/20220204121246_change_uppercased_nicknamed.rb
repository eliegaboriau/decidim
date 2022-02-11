# frozen_string_literal: true

class ChangeUppercasedNicknamed < ActiveRecord::Migration[6.0]
  def up
    logger = Logger.new($stdout)
    logger.info("Updating users nickname ...")

    # list of users already changed in the process
    has_changed = []

    Decidim::User.find_each do |user|
      next if has_changed.include? user
      # if already downcased, don't care
      next if user.nickname.downcase == user.nickname

      Decidim::User.where("nickname ILIKE ?", user.nickname.downcase).order(:created_at).each_with_index do |similar_user, index|
        next if has_changed.include? similar_user
        next if user == similar_user

        # change his nickname to the lowercased one with 5 random numbers
        begin
          update_user_nickname(similar_user,"#{similar_user.nickname.downcase}-#{rand(99999)}")
        rescue ActiveRecord::RecordInvalid => e
          logger.warn("Nickname already taken : #{e}")
          update_user_nickname(similar_user,"#{similar_user.nickname.downcase}-#{rand(99999)}")
        end

        logger.info("User similar ID : #{similar_user.id}")
        logger.info("to #{similar_user.nickname}")
        has_changed.append(similar_user)
      end

      update_user_nickname(user,user.nickname.downcase)
      logger.info("User ID : #{user.id}")
      logger.info("to #{user.nickname}")
      has_changed.append(user)
    end
    logger.info("Process terminated, #{has_changed.count} users nickname have been updated.")
  end

  def send_notification_to(user, new_nickname)
    Decidim::EventsManager.publish({
                                     event: "decidim.events.nickname_event",
                                     event_class: Decidim::ChangeNicknameEvent,
                                     affected_users: [user],
                                     resource: user,
                                     extra: {
                                       old_nickname: user.nickname,
                                       new_nickname: new_nickname
                                     }
                                   })
  end

  def update_user_nickname(user, new_nickname)
    if user.update!(nickname: new_nickname)
      send_notification_to(user, new_nickname)
      logger.warn("User updated")
      user
    else
      logger.warn("An error happened")
    end
  end
end
