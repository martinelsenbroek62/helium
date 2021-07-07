module OrganizationsHelper

  def organization_logo
    if _organization && _organization.logo.present?
      cl_image_tag(
        _organization.logo['public_id'],
        width:200,
        height:50
      )
    else
      image_tag "logo@2x.png", style: "max-width:200px"
    end.html_safe
  end

  def empty_table_rows(colspan=10, rowspan=10)
    message = "" # "<tr><td colspan='#{colspan}' class='center'><span class='muted'>No records found</span></td></tr>"
    (message + (rowspan.times.map do
      "<tr>" << (colspan).times.map do
        "<td><div style='width:#{random_width}%;height:10px;background:whitesmoke'></div></td>"
      end.join << "</tr>"
    end.join)).html_safe
  end

  def random_width
    x = 0
    while x < 20
      x = rand(100)
    end
    x
  end
end
