namespace :data do
  namespace :version_1_4_0 do
    task :set_finish_date_on_child_surveys => :environment do
      Survey.where.not(master_id:nil).each do |survey|
        survey.update_column(:finish_date, survey.master.finish_date) if survey.master.finish_date.present?
        puts "[update] #{survey.id}"
      end
    end

    task :merge_duplicate_users => :environment do

      user_from_id = 296
      user_to_id = 2742

      user_from = User.find(user_from_id)
      user_to = User.find(user_to_id)

      user_from.surveys.each do |survey|
        survey.questions.update_all(user_id: user_to.id)
        survey.results.update_all(user_id: user_to.id)
        survey.historical_records.update_all(user_id: user_to.id)
        survey.update_column(:user_id, user_to.id)
      end

      user_from.update_column(:email, "#{user_from.email}.bak")

      user_from_id = 129
      user_to_id = 2733

      user_from = User.find(user_from_id)
      user_to = User.find(user_to_id)

      user_from.surveys.each do |survey|
        survey.questions.update_all(user_id: user_to.id)
        survey.results.update_all(user_id: user_to.id)
        survey.historical_records.update_all(user_id: user_to.id)
        survey.update_column(:user_id, user_to.id)
      end

      user_from.update_column(:email, "#{user_from.email}.bak")

      #
      user_from_id = 266
      user_to_id = 2736

      user_from = User.find(user_from_id)
      user_to = User.find(user_to_id)

      user_from.surveys.each do |survey|
        survey.questions.update_all(user_id: user_to.id)
        survey.results.update_all(user_id: user_to.id)
        survey.historical_records.update_all(user_id: user_to.id)
        survey.update_column(:user_id, user_to.id)
      end

      user_from.update_column(:email, "#{user_from.email}.bak")
    end
  end
end
