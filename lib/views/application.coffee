editor = ace.edit('editor')
editor.setTheme('ace/theme/tomorrow')
editor.session.setMode('ace/mode/sql')

editor.setValue """
/*
Enter your SQL query below.
You can run, save, or delete queries using the buttons above
*/

SELECT *
FROM users
"""

editorSession = editor.getSession()

editor.setShowPrintMargin(false)
editor.renderer.setShowGutter(false)

editorSession.setTabSize(2)
editorSession.setUseSoftTabs(true)

filterEditor = ace.edit('filter-editor')
filterEditor.setTheme('ace/theme/tomorrow')
filterEditor.session.setMode('ace/mode/javascript')

filterEditor.setValue """
// Enter your JavaScript filter below.
// Filters modify the returned SQL dataset
// Query results are available for manipulation
// via the global variable `results`
window.names = results.map(function(result, index) {
  return result.first_name + " " + results.last_name
});
"""

filterSession = filterEditor.getSession()

filterEditor.setShowPrintMargin(false)
filterEditor.clearSelection()

filterEditor.renderer.setShowGutter(false)

filterSession.setTabSize(2)
filterSession.setUseSoftTabs(true)

$ ->
  addQuery = (data) ->
    queryName = if data.name.length then data.name else "Query \#{data.id}"

    $query = "<li class='query' data-content='\#{data.content}' data-filter='\#{data.filter}' data-name='\#{data.name}' data-id='\#{data.id}''>\#{queryName}</li>"

    $('.queries').append $query

  updateQueryName = (newName) ->
    $('header .title .name').removeClass('display-none').text(newName)
    $('header .title .edit-title').addClass('display-none')

    if ($query = $('.query.active')).length
      $query.text(newName)
      $query.attr('data-name', newName)

  resultsTable = (data) ->
    # export results to the global scope
    # so people can tweak them.
    window.results = data.items

    $('.results thead, .results tbody').empty()

    for column in data.columns
      $('table thead').append "<th>\#{column}</th>"

    for item in data.items
      $tr = $('<tr>')

      for key, value of item
        $tr.append "<td>\#{value}</td>"

      $('table tbody').append $tr

    debugger

  $(document).on 'click', (e) ->
    $target = $(e.target)

    return if $target.is('.title .edit-title, .title h2')

    name = $('header .title .edit-title').val()

    updateQueryName(name)

  $('header .title .edit-title').on 'keydown', (e) ->
    return unless e.keyCode is 13

    name = $('header .title .edit-title').val()

    updateQueryName(name)

  $('header .title h2').on 'click', (e) ->
    $target = $(e.currentTarget)

    width = $target.width()

    $target.addClass 'display-none'
    $target.next().removeClass('display-none').width(width).select()

  $('.file-tree').on 'click', '.query', (e) ->
    $target = $(e.currentTarget)

    $('.query').removeClass 'active'

    $target.addClass 'active'

    editor.setValue $target.attr('data-content')
    filterEditor.setValue $target.attr('data-filter')

    $('header .title .name').text($target.text())
    $('header .title .edit-title').val($target.text())

  $('.btn-show-results').on 'click', (e) ->
    $target = $(e.currentTarget)

    $editor = $('#editor')
    $results = $('#results')

    $target.toggleClass 'active'

    if $target.is('.active')
      $('.query-content').addClass('display-none')
      $('.results-content').removeClass('display-none')
    else
      $('.query-content').removeClass('display-none')
      $('.results-content').addClass('display-none')

  $('.btn-save').on 'click', ->
    $.ajax
      type: 'POST'
      url: '/queries'
      data:
        content: editor.getValue()
        filter: filterEditor.getValue()
        name: $('header .title .name').text()
      dataType: 'json'
      success: addQuery

  $('.btn-run').on 'click', ->
    $.ajax
      type: 'GET'
      url: '/run'
      data:
        content: editor.getValue()
      dataType: 'json'
      success: resultsTable

  $('.btn-delete').on 'click', ->
    $query = $('.query.active')

    alert "You must select a query to delete" unless $query.length

    id = $query.data('id')
    queryName = if $query.data('name').length then $query.data('name') else "Query \#{id}"

    if confirm "Are you sure you want to delete \#{queryName}"
      $.ajax
        type: 'DELETE'
        url: "queries/\#{id}"
        dataType: 'json'
        success: ->
          $query.remove()
