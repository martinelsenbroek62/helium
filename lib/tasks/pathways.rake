namespace :pathways do
  task :assign_users_and_surveys_to_organizations => :environment do
    {
      "Middlebury College" => "2016 Middlebury College Household Sustainability Survey",
      "Ben & Jerry's" => "2016 Ben & Jerry's Household Carbon Survey",
      "Seventh Generation" => "Carbon Assessment for LEAD H1",
      "Odell Brewery" => "Odell Sustainability Survey",
      "New Belgium Brewery" => "New Belgium Brewery Sustainability Survey",
      "City of Fort Collins" => "City of Fort Collins (rev2)",
      "King Arthur Flour" => "2016 King Arthur Flour Household Carbon Survey (draft)",
      "National Life Group" => "2016 National Life Group Household Sustainability Survey",
      "VEIC" => "2015 VEIC Carbon Survey"
    }.each do |organization_name, survey_name|
      puts "Updating #{organization_name} #{survey_name}"
      organization = Organization.where(name: organization_name).first_or_create

      Survey.where(name: survey_name).each do |survey|
        survey.update(organization_id: organization.id)
        survey.user.update(organization_id: organization.id) if survey.user.present?
      end

      organization.update(has_surveys:true)
    end
  end

  task :assign_question_identifiers_old_X => :environment do
    rows = File.read("#{Rails.root}/data/GusQuestions.tsv").split("\n").map do |line|
      line = line.strip.split("\t")
      row = {
        cell: line[9],
        key: line[10],
        identifier: line[19]
      }

      puts Question.where(question_identifier:nil, cell: row[:cell], key: row[:key]).update_all(question_identifier: row[:identifier])
      puts row
    end
  end

  task :assign_question_identifiers => :environment do
    rows = File.read("#{Rails.root}/data/question_ids.tsv").split("\n").map do |line|
      line = line.strip.split("\t")

      row = {
        question_identifier: line[0],
        question_text: line[1],
        section_name: line[2],
        group_name: line[3],
        question_join_key: line[4],
        campaign: line[5],
        cell: line[6],
        key: line[7],
        question_updated: line[8]
      }

      if survey = Survey.where(name: row[:campaign]).first
        if section = survey.sections.where(name: row[:section_name]).first
          if group = section.groups.where(name: row[:group_name]).first
            if question = group.questions.where(cell: row[:cell], key: row[:key]).first
              puts question.update(question_identifier: row[:question_identifier]), row[:campaign], row[:question_text]
            end
          end
        end
      end
    end
  end

  task :update_master_uuids_for_existing_surveys => :environment do
    Survey.all.each do |survey|
      survey.delay.update_from_master_old!
    end
  end

end
