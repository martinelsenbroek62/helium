module SpreadsheetConcern
  G_CLIENT_ID = (ENV['G_CLIENT_ID'] ||= "962112517044-aobl7sjlurcugjhvj0i92tqjfrlujd38.apps.googleusercontent.com")
  G_CLIENT_EMAIL = (ENV['G_CLIENT_EMAIL'] ||= "962112517044-aobl7sjlurcugjhvj0i92tqjfrlujd38@developer.gserviceaccount.com")

  def spreadsheet_name
    if master?
      [uuid, File.basename(spreadsheet.to_s.strip)].join('-')
    else
      [uuid, master.spreadsheet_name].join('-')
    end
  end

  def upload!
    return if spreadsheet.blank? || !master?

    if remote_spreadsheet
      remote_spreadsheet.delete(true)
    end

    google_client.upload_from_file(spreadsheet, spreadsheet_name, user: G_CLIENT_EMAIL)
  end

  def copy!
    return if master?

    current_spreadsheet = remote_spreadsheet
    if current_spreadsheet
      remote_spreadsheet.delete
    end

    master.remote_spreadsheet.copy(spreadsheet_name)
  end

  def import!
    if only_import_report_questions == true
      section_position = 999
      group_position = 999
      question_position = 999
    else
      section_position = 1
      group_position = 1
      question_position=1
    end

    questions_from_spreadsheet.group_by { |row| row['category'] }.each do |section_name, rows|
      if (only_import_report_questions == true) && !(section_name =~ /goals/i)
        next
      end

      section_name = section_name.strip

      section = sections.where(name: section_name, organization_id:organization_id, survey_id:id).first_or_create
      section.update(position: section_position)
      section_position += 1

      group_position = 1
      rows.group_by { |row| row['group_category'] }.each do |group_category_name, question_rows|

        group = section.groups.where(organization_id: organization_id, section_id: section.id, survey_id:id, name:group_category_name).first_or_create
        group.update(position: group_position)
        group_position+=1

        question_rows.each do |row|
          if false # row['question_identifier'].present? # TODO - we can use this on new surveys  in the future
            q = group.questions.where(
              section_id: section.id,
              group_id: group.id,
              survey_id: id,
              organization_id:organization_id,
              question_identifier: row['question_identifier']
            ).first_or_create
          else
            q = group.questions.where(
              section_id: section.id,
              group_id: group.id,
              survey_id: id,
              organization_id:organization_id,
              key: row['key']
            ).first_or_create
          end

          q.update(
            row.slice('text', 'key', 'more_info','kind','options','required','cell','units','placeholder', 'question_identifier', 'show_previous_answers', 'question_identifier')
          )

          q.update(position: question_position)
          question_position+=1
        end
      end
    end

    questions_from_spreadsheet.each do |row|
      if (only_import_report_questions == true) && !(row['category'] =~ /goals/i)
        next
      end

      if row['logic'].to_s.strip.present? && row['parent_key'].strip != row['key']
        operator = row['logic'].strip
        value = row['condition']

        operator = if operator == '='
          'equals'
        elsif operator =~ /\</i
          'less than'
        elsif operator =~ /\>/i
          'greater than'
        else
          operator
        end

        if answer_from = questions.where(key: row['parent_key'].strip).first
          if question = questions.where(key:row['key']).first
            rule = question.rules.where(
              survey_id:id,
              organization_id: organization_id,
              operator:operator,
              value:value,
              answer_from_id: answer_from.try(:id)
            ).first_or_create
          end
        end
      end
    end
  end

  def questions_from_spreadsheet
    headers = %w{category text more_info response placeholder options kind required cell1 cell key parent_key logic condition test group_name units mothballed report question_identifier show_previous_answers}

    qs = (_questions_sheet.rows[1..-1]).map {|row| Hash[headers.zip(row)] }.map do |row|
      cat = row['category']
      row.delete('test')
      row['dependencies'] = [row['logic'], row['condition']].join(' ')
      row['group_category'] = (row['group_name'].present? ? row['group_name'] : 'Group N/A')
      row['category'] = (row['category'].present? ? row['category'] : 'Section N/A')
      row['required'] = (row['required']=~/y/i ? true : false)
      row['show_previous_answers'] = (row['show_previous_answers'].present? && row['show_previous_answers'] =~ /y/i ? true : false)
      row.delete('report')
      row.delete('mothballed')
      row
    end
  end

  def update_answers!
    self.questions.each do |question|
      next if question.answer.blank?

      question.cell.to_s.split(',').each do |cell|
        next if cell =~ /cell|response/i

        _questions_sheet[cell] = question.answer
      end
    end

    _questions_sheet.save
  end

  def get_results!
    headers = %w{key value}
    _results_sheet.rows.map { |row| Hash[headers.zip(row)] }.map do |row|
      result = results.where(organization_id: organization_id, key: row['key']).first_or_create
      value = row['value'].to_s.gsub(/[^0-9\.]/, '').try(:to_f)

      result.update(value: value)
      result
    end
  end

  def copy_update_answers_and_get_results!
    copy! # make sure we're using the latest version
    update_answers! # update spreadsheet w/ all answers
    get_results! # pull down calculated results
  end

  def _spreadsheet # Google API has changed
    if !master?
      @_spreadsheet ||= google_client.spreadsheet_by_title(spreadsheet_name)
    else
      if created_at >= Date.parse("January 1st 2019")
        @_spreadsheet ||= google_client.spreadsheet_by_title(File.basename(spreadsheet_name, '.*'))
      else
        @_spreadsheet ||= google_client.spreadsheet_by_title(spreadsheet_name)
      end
    end
  end

  def _results_sheet
    @_results_sheet ||= _spreadsheet.worksheets[1]
  end

  def _questions_sheet
    @_questions_sheet ||= _spreadsheet.worksheets[0]
  end

  def self._spreadsheets
    google_client.files.each do |file|
      puts file.title
    end
  end

  def remote_spreadsheet
    @remote_spreadsheet ||= _spreadsheet
  end

  def share_spreadsheet_with(gmail_address=nil)
    return unless gmail_address

    remote_spreadsheet.acl.push({
      type: "user",
      value: gmail_address,
      role: "writer"
    })
  end

  def google_client
    return @client if defined?(@client)

    client_id    = G_CLIENT_ID
    client_email = G_CLIENT_EMAIL
    fingerprint  = "4760ecc89f03f9e91a590a28047d377d4f8c6ec9"

    client = Google::APIClient.new
    auth = client.authorization
    auth.scope = "https://www.googleapis.com/auth/drive https://spreadsheets.google.com/feeds/"

    p12 = "#{Rails.root}/data/VEICCARBONSURVEY2-4760ecc89f03.p12"
    key = Google::APIClient::KeyUtils.load_from_pkcs12(p12, 'notasecret')

    client.authorization = Signet::OAuth2::Client.new(
      :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
      :audience => 'https://accounts.google.com/o/oauth2/token',
      :scope => 'https://www.googleapis.com/auth/drive https://spreadsheets.google.com/feeds/',
      :issuer => client_email,
      :signing_key => key)
    access_token = client.authorization.fetch_access_token!

    @access_token = access_token["access_token"]
    @client = GoogleDrive.login_with_oauth(@access_token)
  end
end

module Google
  class APIClient
  def initialize(options={})
      logger.debug { "#{self.class} - HELLO Initializing client with options #{options}" }

      # Normalize key to String to allow indifferent access.
      options = options.inject({}) do |accu, (key, value)|
        accu[key.to_sym] = value
        accu
      end
      # Almost all API usage will have a host of 'www.googleapis.com'.
      self.host = options[:host] || 'www.googleapis.com'
      self.port = options[:port] || 443
      self.discovery_path = options[:discovery_path] || '/discovery/v1'

      # Most developers will want to leave this value alone and use the
      # application_name option.
      if options[:application_name]
        app_name = options[:application_name]
        app_version = options[:application_version]
        application_string = "#{app_name}/#{app_version || '0.0.0'}"
      else
        logger.warn { "#{self.class} - Please provide :application_name and :application_version when initializing the client" }
      end

      proxy = options[:proxy] || Object::ENV["http_proxy"]

      self.user_agent = "google-api-ruby-client"
      # options[:user_agent] || (
      #   "#{application_string} " +
      #   "google-api-ruby-client/#{Google::APIClient::VERSION::STRING} #{ENV::OS_VERSION} (gzip)"
      # ).strip
      # The writer method understands a few Symbols and will generate useful
      # default authentication mechanisms.
      self.authorization =
        options.key?(:authorization) ? options[:authorization] : :oauth_2
      if !options['scope'].nil? and self.authorization.respond_to?(:scope=)
        self.authorization.scope = options['scope']
      end
      self.auto_refresh_token = options.fetch(:auto_refresh_token) { true }
      self.key = options[:key]
      self.user_ip = options[:user_ip]
      self.retries = options.fetch(:retries) { 0 }
      self.expired_auth_retry = options.fetch(:expired_auth_retry) { true }
      @discovery_uris = {}
      @discovery_documents = {}
      @discovered_apis = {}
      ca_file = options[:ca_file] || File.expand_path('../../cacerts.pem', __FILE__)
      self.connection = Faraday.new do |faraday|
        faraday.response :charset if options[:force_encoding]
        faraday.response :gzip
        faraday.options.params_encoder = Faraday::FlatParamsEncoder
        faraday.ssl.ca_file = ca_file
        faraday.ssl.verify = true
        faraday.proxy proxy
        faraday.adapter Faraday.default_adapter
        if options[:faraday_option].is_a?(Hash)
          options[:faraday_option].each_pair do |option, value|
            faraday.options.send("#{option}=", value)
          end
        end
      end
      return self
    end
  end
end
