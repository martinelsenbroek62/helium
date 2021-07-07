# https://www.samltool.com/self_signed_certs.php
# https://www.quora.com/Is-there-any-online-SAML-IdP-that-can-be-used-for-testing-our-SAML-SP

class SamlController < ApplicationController
  skip_before_action :verify_authenticity_token,
    :require_user

  # https://auth0.com/blog/how-saml-authentication-works/

  def index
    @attrs = {}
  end

  def sso
    settings = get_saml_settings(get_url_base)
    request = OneLogin::RubySaml::Authrequest.new
    redirect_to(request.create(settings))
  end

  # Handles response from identity provider after authentication
  def acs
    settings = get_saml_settings(get_url_base)
    response = OneLogin::RubySaml::Response.new(params[:SAMLResponse], :settings => settings)

    if response.is_valid?
      session[:nameid] = response.nameid
      session[:attributes] = response.attributes
      @attrs = session[:attributes]
      @email = @attrs.select { |k,v| v.first=~/@/i}.first.last.last rescue nil

      @saml_idp_id = @attrs["id"]
      @saml_idp = params[:idp]

      puts "ZZZ"
      puts @attrs.inspect
      puts "ZZZ"

      # Find user by saml_idp_id and saml_idp (e.g., medwellness, 123)
      # These users should be returning users that have already linked their accounts (gone through process in code blocks below)
      @user = User.where(saml_idp:params[:idp].to_s.strip, saml_idp_id: @id).first
      unless @user
        # No user? Ok, they may only have a saml_idp bc they are imported but not linked yet
        # Let's see if we can find them by email and saml_idp_id
        @user = User.where(email: @email, saml_idp_id: @saml_idp_id).first
        @user.update(saml_idp:@saml_idp) if @user # let's set the idp so that next time we don't have to do this
        unless @user
          # No, Ok... let's just look for the user just by email.. and assign the saml_idp and saml_idp_id for next time
          @user = User.where(email: @email).first # New user from idp provider
          @user.update(saml_idp:@saml_idp, saml_idp_id:@saml_idp_id) if @user
        end
      end

      if @user
        sign_in(@user)
        redirect_to root_path
        return
      end

      render text: "Unable to find that username/password #{@id} => #{@email}"
    else
      logger.info "Response Invalid. Errors: #{response.errors}"
      @errors = response.errors
      render :action => :fail
    end
  end

  def metadata
    settings = get_saml_settings(get_url_base)
    meta = OneLogin::RubySaml::Metadata.new
    render :xml => meta.generate(settings, true)
  end

  # Trigger SP and IdP initiated Logout requests
  def logout
    # If we're given a logout request, handle it in the IdP logout initiated method
    if params[:SAMLRequest]
      return idp_logout_request

    # We've been given a response back from the IdP
    elsif params[:SAMLResponse]
      return process_logout_response
    elsif params[:slo]
      return sp_logout_request
    else
      reset_session
    end
  end

  # Create an SP initiated SLO
  def sp_logout_request
    # LogoutRequest accepts plain browser requests w/o paramters
    settings = get_saml_settings(get_url_base)

    if settings.idp_slo_target_url.nil?
      logger.info "SLO IdP Endpoint not found in settings, executing then a normal logout'"
      reset_session
    else

      # Since we created a new SAML request, save the transaction_id
      # to compare it with the response we get back
      logout_request = OneLogin::RubySaml::Logoutrequest.new()
      session[:transaction_id] = logout_request.uuid
      logger.info "New SP SLO for User ID: '#{session[:nameid]}', Transaction ID: '#{session[:transaction_id]}'"

      if settings.name_identifier_value.nil?
        settings.name_identifier_value = session[:nameid]
      end

      relayState = url_for controller: 'saml', action: 'index'
      redirect_to(logout_request.create(settings, :RelayState => relayState))
    end
  end

  # After sending an SP initiated LogoutRequest to the IdP, we need to accept
  # the LogoutResponse, verify it, then actually delete our session.
  def process_logout_response
    settings = get_saml_settings(get_url_base)
    request_id = session[:transaction_id]
    logout_response = OneLogin::RubySaml::Logoutresponse.new(params[:SAMLResponse], settings, :matches_request_id => request_id, :get_params => params)
    logger.info "LogoutResponse is: #{logout_response.response.to_s}"

    # Validate the SAML Logout Response
    if not logout_response.validate
      error_msg = "The SAML Logout Response is invalid.  Errors: #{logout_response.errors}"
      logger.error error_msg
      render :inline => error_msg
    else
      # Actually log out this session
      if logout_response.success?
        logger.info "Delete session for '#{session[:nameid]}'"
        reset_session
      end
    end
  end

  # Method to handle IdP initiated logouts
  def idp_logout_request
    settings = get_saml_settings(get_url_base)
    logout_request = OneLogin::RubySaml::SloLogoutrequest.new(params[:SAMLRequest], :settings => settings)
    if not logout_request.is_valid?
      error_msg = "IdP initiated LogoutRequest was not valid!. Errors: #{logout_request.errors}"
      logger.error error_msg
      render :inline => error_msg
    end
    logger.info "IdP initiated Logout for #{logout_request.nameid}"

    # Actually log out this session
    reset_session

    logout_response = OneLogin::RubySaml::SloLogoutresponse.new.create(settings, logout_request.id, nil, :RelayState => params[:RelayState])
    redirect_to logout_response
  end

  def get_url_base
	   "#{request.protocol}#{request.host_with_port}"
  end


  private

  def identity_providers
    @url_base = get_url_base
    {
      'circlesso' => {
        'issuer' => @url_base + "/saml/#{params[:idp]}/metadata",
        'assertion_consumer_service_url' => @url_base + "/saml/#{params[:idp]}/acs",
        'idp_entity_id' => "https://idp.ssocircle.com",
        'idp_sso_target_url' => "https://idp.ssocircle.com:443/sso/SSORedirect/metaAlias/publicidp",
        'name_identifier_format' => "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress",
        'idp_cert' => "MIIEYzCCAkugAwIBAgIDIAZmMA0GCSqGSIb3DQEBCwUAMC4xCzAJBgNVBAYTAkRF MRIwEAYDVQQKDAlTU09DaXJjbGUxCzAJBgNVBAMMAkNBMB4XDTE2MDgwMzE1MDMy M1oXDTI2MDMwNDE1MDMyM1owPTELMAkGA1UEBhMCREUxEjAQBgNVBAoTCVNTT0Np cmNsZTEaMBgGA1UEAxMRaWRwLnNzb2NpcmNsZS5jb20wggEiMA0GCSqGSIb3DQEB AQUAA4IBDwAwggEKAoIBAQCAwWJyOYhYmWZF2TJvm1VyZccs3ZJ0TsNcoazr2pTW cY8WTRbIV9d06zYjngvWibyiylewGXcYONB106ZNUdNgrmFd5194Wsyx6bPvnjZE ERny9LOfuwQaqDYeKhI6c+veXApnOfsY26u9Lqb9sga9JnCkUGRaoVrAVM3yfghv /Cg/QEg+I6SVES75tKdcLDTt/FwmAYDEBV8l52bcMDNF+JWtAuetI9/dWCBe9VTC asAr2Fxw1ZYTAiqGI9sW4kWS2ApedbqsgH3qqMlPA7tg9iKy8Yw/deEn0qQIx8Gl VnQFpDgzG9k+jwBoebAYfGvMcO/BDXD2pbWTN+DvbURlAgMBAAGjezB5MAkGA1Ud EwQCMAAwLAYJYIZIAYb4QgENBB8WHU9wZW5TU0wgR2VuZXJhdGVkIENlcnRpZmlj YXRlMB0GA1UdDgQWBBQhAmCewE7aonAvyJfjImCRZDtccTAfBgNVHSMEGDAWgBTA 1nEA+0za6ppLItkOX5yEp8cQaTANBgkqhkiG9w0BAQsFAAOCAgEAAhC5/WsF9ztJ Hgo+x9KV9bqVS0MmsgpG26yOAqFYwOSPmUuYmJmHgmKGjKrj1fdCINtzcBHFFBC1 maGJ33lMk2bM2THx22/O93f4RFnFab7t23jRFcF0amQUOsDvltfJw7XCal8JdgPU g6TNC4Fy9XYv0OAHc3oDp3vl1Yj8/1qBg6Rc39kehmD5v8SKYmpE7yFKxDF1ol9D KDG/LvClSvnuVP0b4BWdBAA9aJSFtdNGgEvpEUqGkJ1osLVqCMvSYsUtHmapaX3h iM9RbX38jsSgsl44Rar5Ioc7KXOOZFGfEKyyUqucYpjWCOXJELAVAzp7XTvA2q55 u31hO0w8Yx4uEQKlmxDuZmxpMz4EWARyjHSAuDKEW1RJvUr6+5uA9qeOKxLiKN1j o6eWAcl6Wr9MreXR9kFpS6kHllfdVSrJES4ST0uh1Jp4EYgmiyMmFCbUpKXifpsN WCLDenE3hllF0+q3wIdu+4P82RIM71n7qVgnDnK29wnLhHDat9rkC62CIbonpkVY mnReX0jze+7twRanJOMCJ+lFg16BDvBcG8u0n/wIDkHHitBI7bU1k6c6DydLQ+69 h8SCo6sO9YuD+/3xAGKad4ImZ6vTwlB4zDCpu6YgQWocWRXE+VkOb+RBfvP755PU aLfL63AFVlpOnEpIio5++UjNJRuPuAA="
      },

      'qa-circlesso' => {
        'issuer' => @url_base + "/saml/#{params[:idp]}/metadata",
        'assertion_consumer_service_url' => @url_base + "/saml/#{params[:idp]}/acs",
        'idp_entity_id' => "https://idp.ssocircle.com",
        'idp_sso_target_url' => "https://idp.ssocircle.com:443/sso/SSORedirect/metaAlias/publicidp",
        'name_identifier_format' => "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress",
        'idp_cert' => "MIIEYzCCAkugAwIBAgIDIAZmMA0GCSqGSIb3DQEBCwUAMC4xCzAJBgNVBAYTAkRF MRIwEAYDVQQKDAlTU09DaXJjbGUxCzAJBgNVBAMMAkNBMB4XDTE2MDgwMzE1MDMy M1oXDTI2MDMwNDE1MDMyM1owPTELMAkGA1UEBhMCREUxEjAQBgNVBAoTCVNTT0Np cmNsZTEaMBgGA1UEAxMRaWRwLnNzb2NpcmNsZS5jb20wggEiMA0GCSqGSIb3DQEB AQUAA4IBDwAwggEKAoIBAQCAwWJyOYhYmWZF2TJvm1VyZccs3ZJ0TsNcoazr2pTW cY8WTRbIV9d06zYjngvWibyiylewGXcYONB106ZNUdNgrmFd5194Wsyx6bPvnjZE ERny9LOfuwQaqDYeKhI6c+veXApnOfsY26u9Lqb9sga9JnCkUGRaoVrAVM3yfghv /Cg/QEg+I6SVES75tKdcLDTt/FwmAYDEBV8l52bcMDNF+JWtAuetI9/dWCBe9VTC asAr2Fxw1ZYTAiqGI9sW4kWS2ApedbqsgH3qqMlPA7tg9iKy8Yw/deEn0qQIx8Gl VnQFpDgzG9k+jwBoebAYfGvMcO/BDXD2pbWTN+DvbURlAgMBAAGjezB5MAkGA1Ud EwQCMAAwLAYJYIZIAYb4QgENBB8WHU9wZW5TU0wgR2VuZXJhdGVkIENlcnRpZmlj YXRlMB0GA1UdDgQWBBQhAmCewE7aonAvyJfjImCRZDtccTAfBgNVHSMEGDAWgBTA 1nEA+0za6ppLItkOX5yEp8cQaTANBgkqhkiG9w0BAQsFAAOCAgEAAhC5/WsF9ztJ Hgo+x9KV9bqVS0MmsgpG26yOAqFYwOSPmUuYmJmHgmKGjKrj1fdCINtzcBHFFBC1 maGJ33lMk2bM2THx22/O93f4RFnFab7t23jRFcF0amQUOsDvltfJw7XCal8JdgPU g6TNC4Fy9XYv0OAHc3oDp3vl1Yj8/1qBg6Rc39kehmD5v8SKYmpE7yFKxDF1ol9D KDG/LvClSvnuVP0b4BWdBAA9aJSFtdNGgEvpEUqGkJ1osLVqCMvSYsUtHmapaX3h iM9RbX38jsSgsl44Rar5Ioc7KXOOZFGfEKyyUqucYpjWCOXJELAVAzp7XTvA2q55 u31hO0w8Yx4uEQKlmxDuZmxpMz4EWARyjHSAuDKEW1RJvUr6+5uA9qeOKxLiKN1j o6eWAcl6Wr9MreXR9kFpS6kHllfdVSrJES4ST0uh1Jp4EYgmiyMmFCbUpKXifpsN WCLDenE3hllF0+q3wIdu+4P82RIM71n7qVgnDnK29wnLhHDat9rkC62CIbonpkVY mnReX0jze+7twRanJOMCJ+lFg16BDvBcG8u0n/wIDkHHitBI7bU1k6c6DydLQ+69 h8SCo6sO9YuD+/3xAGKad4ImZ6vTwlB4zDCpu6YgQWocWRXE+VkOb+RBfvP755PU aLfL63AFVlpOnEpIio5++UjNJRuPuAA="
      },

      'qa-medwellness' => {
        'issuer' => @url_base + "/saml/#{params[:idp]}/metadata",
        'assertion_consumer_service_url' => @url_base + "/saml/#{params[:idp]}/acs",
        'idp_entity_id' => "https://www.mymedwellness.com/simplesaml/saml2/idp/metadata.php",
        'idp_sso_target_url' => "https://www.mymedwellness.com/simplesaml/saml2/idp/SSOService.php",
        'name_identifier_format' => "urn:oasis:names:tc:SAML:2.0:nameid-format:emailAddress",
        'idp_cert' =>  "MIIEujCCA6KgAwIBAgIJAJrlnZIh0cpFMA0GCSqGSIb3DQEBBQUAMIGZMQswCQYDVQQGEwJVUzEVMBMGA1UECBMMUGVubnN5bHZhbmlhMRMwEQYDVQQHEwpQaXR0c2J1cmdoMRMwEQYDVQQKEwpXaWxsQ2xvd2VyMQ8wDQYDVQQLEwZIZWFsdGgxFDASBgNVBAMTC1dpbGwgQ2xvd2VyMSIwIAYJKoZIhvcNAQkBFhN3aWxsQHdpbGxjbG93ZXIuY29tMB4XDTE2MDUwNDEzMzk1M1oXDTI2MDUwNDEzMzk1M1owgZkxCzAJBgNVBAYTAlVTMRUwEwYDVQQIEwxQZW5uc3lsdmFuaWExEzARBgNVBAcTClBpdHRzYnVyZ2gxEzARBgNVBAoTCldpbGxDbG93ZXIxDzANBgNVBAsTBkhlYWx0aDEUMBIGA1UEAxMLV2lsbCBDbG93ZXIxIjAgBgkqhkiG9w0BCQEWE3dpbGxAd2lsbGNsb3dlci5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC0wBhm4yrmVMa7kKXeW91xGel7ZW22asahkoG5WhSVqWPnDe+6BvXQh4FxZdEcj7cqrOA7Am+1OBtktAhU3wT+NsrhH2ArOGy7V+s/cwGM+AjGD3k6I8AtUrAYTpkuXnbFWKbZybcX0UjJlTxfcPUlYjiufBXJ7TtfccxUsKNlDHE/qFvDrKj8SinA5CNuChYI2GajKEDlbKZ9NWwvGW3vFKh2217wx6JUPJQCXRjZbRYMURR7mCAcEPYkSQFvylnjQrkgSwzM+nzGE2GAQ3fIm9tbusnUpNI30/x9t+H/udeDkfEaV0Vr/li0LDfHKzvY9BwQajYzJkdP8tVPIT/TAgMBAAGjggEBMIH+MB0GA1UdDgQWBBQMZmixdWDoKeiKRaQdP4KXQ1IKEjCBzgYDVR0jBIHGMIHDgBQMZmixdWDoKeiKRaQdP4KXQ1IKEqGBn6SBnDCBmTELMAkGA1UEBhMCVVMxFTATBgNVBAgTDFBlbm5zeWx2YW5pYTETMBEGA1UEBxMKUGl0dHNidXJnaDETMBEGA1UEChMKV2lsbENsb3dlcjEPMA0GA1UECxMGSGVhbHRoMRQwEgYDVQQDEwtXaWxsIENsb3dlcjEiMCAGCSqGSIb3DQEJARYTd2lsbEB3aWxsY2xvd2VyLmNvbYIJAJrlnZIh0cpFMAwGA1UdEwQFMAMBAf8wDQYJKoZIhvcNAQEFBQADggEBAHCTsWuM/8O67Wp7ngQgqOynFioM26s4SJoSuM3bsmEe7oPifsCq8SQ2rGZQf554umGAdMR0ycdB0wDu9ItczwVynLuM0Ie6xvhXKXG62rOuXV1keLkMrd3VhRBAZ2AONl6iYwJpnH1NHp+kjjQwRJ52agJ61CfnhX+MsP3eqwzqXQ1RRb30HdkyS7GEOHfvFMnkX3hE17twGID5DgjVC6/olPYaLP17oEPAOd7QP/ILhMCFJbpFhgAbodLCqr0njx0xwTardy9SthwtcDi+rQeP8Cx9od91W7HJ8HOPo0ay+JeFvdFheJAO4rq94qX4aZdvMyKgDjzrOX4x/5rxoVo="
      },
      'medwellness' => {
        'issuer' => @url_base + "/saml/#{params[:idp]}/metadata",
        'assertion_consumer_service_url' => @url_base + "/saml/#{params[:idp]}/acs",
        'idp_entity_id' => "https://www.mymedwellness.com/simplesaml/saml2/idp/metadata.php",
        'idp_sso_target_url' => "https://www.mymedwellness.com/simplesaml/saml2/idp/SSOService.php",
        'name_identifier_format' => "urn:oasis:names:tc:SAML:2.0:nameid-format:emailAddress",
        'idp_cert' =>  "MIIEujCCA6KgAwIBAgIJAJrlnZIh0cpFMA0GCSqGSIb3DQEBBQUAMIGZMQswCQYDVQQGEwJVUzEVMBMGA1UECBMMUGVubnN5bHZhbmlhMRMwEQYDVQQHEwpQaXR0c2J1cmdoMRMwEQYDVQQKEwpXaWxsQ2xvd2VyMQ8wDQYDVQQLEwZIZWFsdGgxFDASBgNVBAMTC1dpbGwgQ2xvd2VyMSIwIAYJKoZIhvcNAQkBFhN3aWxsQHdpbGxjbG93ZXIuY29tMB4XDTE2MDUwNDEzMzk1M1oXDTI2MDUwNDEzMzk1M1owgZkxCzAJBgNVBAYTAlVTMRUwEwYDVQQIEwxQZW5uc3lsdmFuaWExEzARBgNVBAcTClBpdHRzYnVyZ2gxEzARBgNVBAoTCldpbGxDbG93ZXIxDzANBgNVBAsTBkhlYWx0aDEUMBIGA1UEAxMLV2lsbCBDbG93ZXIxIjAgBgkqhkiG9w0BCQEWE3dpbGxAd2lsbGNsb3dlci5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC0wBhm4yrmVMa7kKXeW91xGel7ZW22asahkoG5WhSVqWPnDe+6BvXQh4FxZdEcj7cqrOA7Am+1OBtktAhU3wT+NsrhH2ArOGy7V+s/cwGM+AjGD3k6I8AtUrAYTpkuXnbFWKbZybcX0UjJlTxfcPUlYjiufBXJ7TtfccxUsKNlDHE/qFvDrKj8SinA5CNuChYI2GajKEDlbKZ9NWwvGW3vFKh2217wx6JUPJQCXRjZbRYMURR7mCAcEPYkSQFvylnjQrkgSwzM+nzGE2GAQ3fIm9tbusnUpNI30/x9t+H/udeDkfEaV0Vr/li0LDfHKzvY9BwQajYzJkdP8tVPIT/TAgMBAAGjggEBMIH+MB0GA1UdDgQWBBQMZmixdWDoKeiKRaQdP4KXQ1IKEjCBzgYDVR0jBIHGMIHDgBQMZmixdWDoKeiKRaQdP4KXQ1IKEqGBn6SBnDCBmTELMAkGA1UEBhMCVVMxFTATBgNVBAgTDFBlbm5zeWx2YW5pYTETMBEGA1UEBxMKUGl0dHNidXJnaDETMBEGA1UEChMKV2lsbENsb3dlcjEPMA0GA1UECxMGSGVhbHRoMRQwEgYDVQQDEwtXaWxsIENsb3dlcjEiMCAGCSqGSIb3DQEJARYTd2lsbEB3aWxsY2xvd2VyLmNvbYIJAJrlnZIh0cpFMAwGA1UdEwQFMAMBAf8wDQYJKoZIhvcNAQEFBQADggEBAHCTsWuM/8O67Wp7ngQgqOynFioM26s4SJoSuM3bsmEe7oPifsCq8SQ2rGZQf554umGAdMR0ycdB0wDu9ItczwVynLuM0Ie6xvhXKXG62rOuXV1keLkMrd3VhRBAZ2AONl6iYwJpnH1NHp+kjjQwRJ52agJ61CfnhX+MsP3eqwzqXQ1RRb30HdkyS7GEOHfvFMnkX3hE17twGID5DgjVC6/olPYaLP17oEPAOd7QP/ILhMCFJbpFhgAbodLCqr0njx0xwTardy9SthwtcDi+rQeP8Cx9od91W7HJ8HOPo0ay+JeFvdFheJAO4rq94qX4aZdvMyKgDjzrOX4x/5rxoVo="
      }
    }
  end

  def get_saml_settings(url_base="http://localhost:3000")
    @idp = identity_providers[params[:idp]]

    settings = OneLogin::RubySaml::Settings.new

    settings.soft = true

    #SP section (this is me)
    settings.issuer                                 = @idp['issuer']
    settings.assertion_consumer_service_url         = @idp['assertion_consumer_service_url']
    # settings.assertion_consumer_logout_service_url  = url_base + "/saml/#{params[:idp]}/logout"

    # IdP section (this is them)
    settings.idp_entity_id                  = @idp['idp_entity_id']
    settings.idp_sso_target_url             = @idp['idp_sso_target_url']
    # settings.idp_slo_target_url           = ''

    settings.name_identifier_format         = @idp['name_identifier_format']

    settings.idp_cert = @idp['idp_cert']

    # or ...
    # settings.idp_cert_fingerprint           = "3B:05:BE:0A:EC:84:CC:D4:75:97:B3:A2:22:AC:56:21:44:EF:59:E6"
    # settings.idp_cert_fingerprint           = "63:4A:B4:65:1F:CA:2F:62:35:63:BE:32:ED:A3:2D:E5:65:21:91:18"
    # settings.idp_cert_fingerprint           = "9E:65:2E:03:06:8D:80:F2:86:C7:6C:77:A1:D9:14:97:0A:4D:F4:4D"
    # settings.idp_cert_fingerprint_algorithm = XMLSecurity::Document::SHA1

    # Security section
    settings.security[:authn_requests_signed] = false
    settings.security[:logout_requests_signed] = false
    settings.security[:logout_responses_signed] = false
    settings.security[:metadata_signed] = false
    settings.security[:digest_method] = XMLSecurity::Document::SHA1
    settings.security[:signature_method] = XMLSecurity::Document::RSA_SHA1

    settings
  end
end
