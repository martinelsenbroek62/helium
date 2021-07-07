json.histogram RawSQL.new('histograms.sql').result(survey_id: _survey.id, master_id: _survey.master_id, key: (params[:key]||'Overall')).map { |row| row}
json.percentiles RawSQL.new('user_percentiles.sql').result(survey_id: _survey.id, master_id: _survey.master_id, key: (params[:key]||'Overall')).map { |row| row}
