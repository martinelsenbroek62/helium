namespace :misc do
  task :set_survey_started_at_and_completed_at => :environment do
    Survey.children.find_in_batches.each do |batch|
      batch.each do |survey|
        q_first = survey.questions.first
        q_last = survey.questions.last

        if q_first
          survey.update(started_at: q_first.updated_at, completed_at: q_last.updated_at)
        end
      end
    end
  end
end
