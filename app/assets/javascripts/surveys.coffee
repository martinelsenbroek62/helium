$ ->

  $(document).on 'page:fetch ajax:before upload:start', ()-> NProgress.start()
  $(document).on 'page:change ajax:complete ajax:success ajax:error upload:stop', ()-> NProgress.done()
  $(document).on 'page:restore', ()-> NProgress.remove()

  $(document).on "ready page:load turbolinks:load", ()->

    $(document).on "keydown", (e)->
      console.log(e.keyCode)
      # 37 <
      # 39 >
      if e.keyCode == 27
        $('.drawer-content').addClass('hide')
        $('tr.expanded').removeClass('expanded')
        $('table.shrink').removeClass('shrink')

    $("[data-progress]").each ()->
      $(@).animate(width: $(@).data("progress"))

    $('input[type=range]').each ()->
      $(@).closest('.range').find('.value').text($(@).val())

      $(@).on 'change input', ()->
        $(@).closest('.range').find('.value').text($(@).val())

    $('input[min]').on 'change', ()->
      _min = parseFloat($(@).attr('min'))
      _max = parseFloat($(@).attr('max'))
      _val = parseFloat($(@).val())

      if _val < _min
        $(@).val(_min)
      if _val > _max
        $(@).val(_max)

    $("[data-complete]").each ()->
      $(@).autocomplete
        source: $(@).data("complete")

    $("body").on "click", ".more-info > a", (e)->
      e.preventDefault()
      $(@).parent().find(".more-info-text").toggleClass("hidden animated fadeInUp")

    if $("body#survey").length
      $('input:first').focus()

      $('input[type=range]').each ()->
        $(@).closest('.range').find('.value').text($(@).val())

        $(@).on 'change mousewheel input', ()->
          $(@).closest('.range').find('.value').text($(@).val())

      $('[data-number]').on 'keyup', ()->
        $(@).val($(@).val().replace(/[^0-9\.]/, ''))

      $("input:not([type=submit]), select, radio, checkbox, range").on 'blur change', ()->
        $(@).closest("form").find("input[type=submit]").removeClass("hidden")
        $(@).closest("form").data("remote", "true").submit().after ()->
          $(@).data("remote", false)

      $("input[type=range]").on "input", ()->
        $(@).prev('input').val($(@).val())

    $(document).on "ajax:success", "form", (e, resp)->
      _resp = JSON.parse(resp)

      _resp.forEach (row)->
        if row.visible
          $("#question_#{row.id}").removeClass('in-visible')
        else
          $("#question_#{row.id}").addClass('in-visible animated fadeInUp')

      _url = location.pathname.split('/').splice(0,5).join('/') + "/info"
      $.ajax
        method: "GET"
        url: _url
        success: (resp)->
          $("[data-progress]").animate
            width: "#{resp.percent_complete}%"
