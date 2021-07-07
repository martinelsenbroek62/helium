namespace :helium do
  task :email_admins_about_new_claim_submissions => :environment do
    Organization.all.each do |organization|
      Claim.delay.email_admins_about_new_claim_submissions(organization)
    end
  end
end
