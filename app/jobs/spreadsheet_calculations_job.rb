class SpreadsheetCalculationsJob < ActiveJob::Base
  queue_as :default

  def perform(*args)
  end
end
