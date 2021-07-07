# https://gist.github.com/seanbehan/c7a1bb80214173202289
class RawSQL
  include ActiveRecord::ConnectionAdapters::Quoting

  def initialize(filename)
    @filename = filename
  end

  def result(params={})
    if params
      ActiveRecord::Base.connection.execute(query % quoted_parameters(params))
    else
      ActiveRecord::Base.connection.execute(query)
    end.map { |row| row }
  end

  private

  attr_reader :filename

  def query
    File.read(Rails.root.join('app/sql', filename))
  end

  def quoted_parameters(params)
    params.each_with_object({}) do |(key, value), result|
      result[key] = if value.is_a?(Array)
        value.map { |item| quote(item) }.join(', ')
      elsif value.is_a?(Integer)
        value
      else
        quote(value)
      end
    end
  end
end
