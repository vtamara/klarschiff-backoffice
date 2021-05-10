#= require tablednd

$ ->
  $(document).ready KS.initDnD
  $(document).on 'turbolinks:load', KS.initDnD

  $(document).on 'click', '.select-all', ->
    $(@).parents('table').find('.selectable').prop('checked', @.checked)

  $(document).on 'click', '.change-status', ->
    ids = $($(@).data('table')).find('.selectable').toArray().filter((e) -> e.checked).map((e) -> e.value)
    return if ids.length == 0
    KS.updateMultipleJobs { job_ids: ids, job: { status: $(@).data('status') } }, 'update_statuses'

  $(document).on 'click', '.change-date', ->
    ids = $($(@).data('table')).find('.selectable').toArray().filter((e) -> e.checked).map((e) -> e.value)
    return if ids.length == 0
    KS.updateMultipleJobs { job_ids: ids, job: { date: $($(@).data('field')).val() } }, 'update_dates'

KS.initDnD = ->
  $('.table-draggable').tableDnD(
    onDragClass: 'dragged-row'
    onDrop: (table, row) ->
      jobsOrder = []
      $(table.rows).each (idx) ->
        jobsOrder.push({ "#{@.dataset.id}": idx })
      $.ajax
        url: '/jobs/change_order'
        data: Object.assign({ jobs: jobsOrder }, KS.authenticityToken)
        dataType: 'script'
        method: 'PUT'
  )

KS.updateMultipleJobs = (params, method) ->
  $.ajax
    url: "/jobs/#{method}"
    data: Object.assign(params, KS.authenticityToken)
    dataType: 'script'
    method: 'PUT'
