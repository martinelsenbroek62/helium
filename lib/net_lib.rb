module Net::HTTPHeader
  def initialize_http_header(initheader)
    @header = {}
    return unless initheader
    initheader.each do |key, value|
      warn "net/http: warning: duplicated HTTP header: #{key}" if key?(key) and $VERBOSE
      value = value.strip # raise error for invalid byte sequences
      if key =~ /User-Agent/
        value = 'google_drive Ruby library/0.4.0 google-api-ruby-client/0.8.7 Mac OS X/10.14.3 (gzip)'
      end

      if value.count("\r\n") > 0
        raise ArgumentError, 'header field value cannot include CR/LF'
      end
      @header[key.downcase] = [value]
    end
  end
end

class Net::HTTPGenericRequest
  def write_header(sock, ver, path)
    reqline = "#{@method} #{path} HTTP/#{ver}"
    if /[\r\n]/ =~ reqline
      raise ArgumentError, "A Request-Line must not contain CR or LF"
    end

    buf = ""
    buf << reqline << "\r\n"
    each_capitalized do |k,v|
      if k =~ /User-Agent/
        v = "google_drive Ruby library/0.4.0 google-api-ruby-client/0.8.7 Mac OS X/10.14.3 (gzip)"
      end

      buf << "#{k}: #{v}\r\n"
    end
    
    buf << "\r\n"
    sock.write buf
  end
end
