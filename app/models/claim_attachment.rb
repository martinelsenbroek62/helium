class ClaimAttachment < ActiveRecord::Base
  belongs_to :claim
  belongs_to :user
  belongs_to :organization

  scope :proof_of_purchase, -> { where(kind: 'proof_of_purchase')}
  scope :proof_of_eligibility, -> { where(kind: 'proof_of_eligibility')}

  def attachment_url
    return '' if attachment.blank?

    attachment['secure_url']
  end

  def image?
    ['.png', '.jpg', '.jpeg', '.gif'].include?('.'+attachment_url.split('.').last)
  end

  def pdf?
    ['.pdf'].include?(attachment_ext)
  end

  def attachment_ext
    '.' + attachment_url.split('.').last
  end

  def name
    File.basename(attachment_url||'')
  end
end
