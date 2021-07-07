json.data do
  json.survey _survey.as_json(methods: [:url, :invalid])

  result_object = {}
  json.results _survey.results.each do |result|
    result_object[result.key] = result.value.to_f rescue 0
    json.key result.key
    json.value result.value.to_f rescue 0
  end

  json.current_results result_object
  json.related_survey_results _survey.related_survey_results

  json.historical _user.historical_records.where(survey_id:_survey.master_id).order('year asc').map { |row| row['data'].except('email', 'full_name', 'location', 'anonymous id') }.reject { |hr| hr['emissions_total'].nil?  }
  json.population   RawSQL.new('population_stats.sql').result(master_id: _survey.master_id).map{ |row| row}

  organization_avg = {year: (_survey.master.organization.name || 'Organization') }
  RawSQL.new('population_stats.sql').result(master_id: _survey.master_id).map{ |row| row }.each do |row|
    organization_avg[row['key']]=row['avg'].to_f rescue 0
  end
  json.organization_averages organization_avg

  histograms = {}
  percentiles = {}

  (params[:histograms]||'').split(',').each do |histogram|
    percentiles[histogram] = RawSQL.new('user_percentiles.sql').result(survey_id: _survey.id, master_id: _survey.master_id, key: histogram).map { |row| row}
    percentiles[histogram + ' per Capita'] = RawSQL.new('user_percentiles.sql').result(survey_id: _survey.id, master_id: _survey.master_id, key: histogram + ' per Capita').map { |row| row}

    histograms[histogram] = RawSQL.new('histograms.sql').result(survey_id: _survey.id, master_id: _survey.master_id, key: histogram).map { |row| row}
    histograms[histogram + ' per Capita'] = RawSQL.new('histograms.sql').result(survey_id: _survey.id, master_id: _survey.master_id, key: histogram+' per Capita').map { |row| row}
  end

  json.histograms histograms
  json.percentiles percentiles
  json.regional_averages Survey.regional_averages

  json.questions _survey.questions.map do |q|
    json.id q.id
    json.options q.options
    json.kind q.kind
    json.question q.text
    json.answer q.answer
  end
end
