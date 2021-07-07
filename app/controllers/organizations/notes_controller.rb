class Organizations::NotesController < OrganizationsController
  def create
    @note = _organization.notes.new(params_for(Note))
    @note.user = _claim.user
    @note.claim = _claim
    @note.author = _user

    @note.save
    redirect_to :back
  end
end
