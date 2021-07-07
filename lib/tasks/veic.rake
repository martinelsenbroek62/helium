require 'csv'

namespace :veic do
  task :import_program_balances => :environment do
    @organization = Organization.find(15)

    Dir["#{Rails.root}/data/VEIC_Benefits/programs/*.csv"].each do |f|
      @program = nil

      lines = File.readlines(f)
      header = lines.shift

      lines.each do |line|
        row = line.parse_csv
        file_number = row[0].to_s.strip
        name = row[1].to_s.strip
        program = row[2].to_s.strip
        balance = row[3].to_s.strip.gsub(/[^0-9\.]/, '').to_f
        email = row[4].to_s.strip

        @program ||= @organization.benefit_programs.where(name: program).first
        if @program
          if user = User.where(email: email).first
            fund = Fund.where(
                organization_id: @organization.id,
                benefit_program_id: @program.id,
                user_id: user.id,
                amount: balance
            ).first_or_create

            puts fund.to_json
          end
        else
          puts "Error: ", row
        end
      end
    end
  end
end
