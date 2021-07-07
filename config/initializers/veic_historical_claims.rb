require 'csv'

VEIC_HISTORICAL_CLAIMS = File.readlines("#{Rails.root}/data/VEIC_Benefits/historical_claims.csv").map(&:strip).map(&:parse_csv)
