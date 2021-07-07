$ ->
  $(document).on "page:load ready", ()->

    $(".organizations-view table tr td:not(.skip)").each ()->
        el = $(@)
        content = el.text().trim()
        unless content.length
          width = 0
          while(width <= 50)
            width = parseInt(Math.random()*100)
          el.html("<div class='empty-cell' style='height:15px;width:#{width}%'>&nbsp;</div>")
