$ ->
  $.extend $.expr[":"],
    "containsI": (elem, i, match, array)->
      (elem.textContent || elem.innerText || "").toLowerCase().indexOf((match[3] || "").toLowerCase()) >= 0


  $(".pagination a").wrap('<li class="page-item"></li>')
  $(".pagination").wrap("<ul class='pagination'></ul>")

  $(document).on "turbolinks:load", ()->
    console.log("a.active")
    
    $("a.active").removeClass("active")
    $("a[href='#{location.pathname + location.search}']").addClass("active")
    $("a[href='#{location.href}']").addClass("active")
