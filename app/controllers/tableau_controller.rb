class TableauController < ApplicationController
  skip_before_filter :require_user
  skip_before_filter :verify_authenticity_token

  include CloudinaryHelper

  def current_org_image
    @file_name = if _organization
      org_name = _organization.id.to_s.parameterize
      if params[:image] =~ /^#{org_name}/i
        "#{params[:image]}"
      else
        "#{_organization.id.to_s.parameterize}_#{params[:image]}"
      end
    else
      params[:image]
    end
    render text: open(cloudinary_url(@file_name)).read
    return
  end

  def any_org_image
    @file_name = params[:image]

    render text: open(cloudinary_url(@file_name)).read
    return
  end

  # test upload
  # curl --request POST --data-binary "@public/img/heart.png" https://qa-pathways.herokuapp.com/tableau/org/15/upload?name=new_dashboard
  def handle_upload
    @organization = Organization.find(params[:organization_id])

    @param_name = (params[:name] ||= 'default').to_s.parameterize
    @file_name = "#{@organization.id.to_s.parameterize}_#{@param_name}"
    @tmp_file_name = "#{SecureRandom.uuid}"

    @file_path = "#{Rails.root}/tmp/#{@file_name}"

    File.open(@file_path, "wb") do |f|
      f.write(request.raw_post)
    end

    @cl_resp = Cloudinary::Uploader.upload(@file_path,
      resource_type: 'auto',
      public_id: @file_name,
      overwrite:true,
      invalidate:true
    )

    # Cloudinary::Uploader.upload(@file_path, resource_type: 'auto', public_id: @tmp_file_name)
    # Cloudinary::Uploader.rename(@tmp_file_name, @file_name, overwrite: true)

    render json: @cl_resp
  end
end
