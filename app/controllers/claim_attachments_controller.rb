class ClaimAttachmentsController < ApplicationController
  def destroy
    @claim_attachment = ClaimAttachment.find_by(uuid:params[:id])
    @claim = @claim_attachment.claim
    @claim_attachment.destroy
    flash[:notice] = "Attachment removed"
    redirect_to @claim
  end
end
