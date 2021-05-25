#= require rails-ujs
#= require jquery
#= require jquery-ui
#= require bootstrap
#= require bootstrap-datepicker
#= require turbolinks
#= require proj4js
#= require ol
#= require_self
#= require_tree .

window.KS ||= {}

$ ->
  $('.modal').on 'hide.bs.modal', ->
    location.reload()

  initDnD = ->
    $('.table-draggable').tableDnD
      onDragClass: 'dragged-row'
  initMap = ->
    if $('#issues-map').length > 0
      KS.initializeMaps()

  $(document).ready KS.initDatepicker
  $(document).ready initDnD
  $(document).on 'turbolinks:load', KS.initDatepicker
  $(document).on 'turbolinks:load', initDnD
  $(document).on 'turbolinks:load', initMap

  $(document).on 'click', '.select-all', ->
    $(@).parents('table').find('.selectable').prop('checked', @.checked)

  updateMultipleJobs = (params) ->
    $.ajax
      url: '/jobs/update_multiple'
      data: params
      dataType: 'script'
      method: 'PUT'

  $(document).on 'keypress', '#search-issue', (e) ->
    if (e.key == 'Enter' || e.keyCode == 13)
      $.get
        url: "/issues/#{@.value}/edit"
        method: 'GET'
        dataType: 'script'
    else
      e.preventDefault() unless e.key.match(/[0-9]/)

  $(document).on 'ajax:complete', 'form', (data) ->
    return if @.id == 'issues-filter'
    $('#notice-success').hide()
    $('#notice-error').hide()
    detail = data.detail[0]
    if detail.response.length > 0
      if detail.status == 200
        $('#notice-success .text').html(detail.response)
        $('#notice-success').show()
      else
        $('#notice-error .text').html(detail.response)
        $('#notice-error').show()

  $(document).on 'click', '.alert .close', (e) ->
    $(e.target).parents('.alert').hide()

KS.authenticityToken = { authenticity_token: $("meta[name='csrf-token']").attr('content') }

KS.initializeModalFunctions = ->
  KS.initializeIssueAddressAutocomplete()
  KS.initializeFormActions()
  KS.initializeMaps()
  KS.initializePhotoActions()
  KS.initializeSelectManyAutocomplete()
  KS.initializeUserLdapAutocomplete()
  KS.initDatepicker()

KS.initDatepicker = ->
  $('.datepicker').datepicker(
    format: 'dd.mm.yyyy'
    language: 'de'
    todayHighlight: true
    autoclose: true
  ).on 'hide', (e) ->
    # Workaround for: https://github.com/uxsolutions/bootstrap-datepicker/issues/50
    e.stopPropagation()

  $(document).on 'click', '#assign-jobs', ->
    ids = $('.selectable').toArray().filter((e) -> e.checked).map((e) -> e.value)
    return false if ids.length == 0
    $('#job-modal').modal()
    console.log(ids)
    for id in ids
      $('form#job-assignment-form').append("<input type='hidden' name='issue_ids[]' value=#{id}>")

  $(document).on 'click', '.show-map', ->
    if @.dataset.extendedFilter == 'true'
      $.get
        url: '/issues?show_map=true&extended_filter=true'
        method: 'GET'
        data: $('form#issues-filter').serialize()
        dataType: 'script'
    else
      $.get
        url: "/issues?status=#{@.dataset.status}&show_map=true"
        method: 'GET'
        dataType: 'script'
