QUERY_LIMIT = 100

## configure editors
editor = ace.edit('editor')

editor.setTheme('ace/theme/tomorrow')
editor.session.setMode('ace/mode/sql')

editorSession = editor.getSession()

editor.setShowPrintMargin(false)
editor.renderer.setShowGutter(false)

editorSession.setTabSize(2)
editorSession.setUseSoftTabs(true)
editorSession.setUseWrapMode(true)
editorSession.setWrapLimitRange(null, null)

filterEditor = ace.edit('filter-editor')
filterEditor.setTheme('ace/theme/tomorrow')
filterEditor.session.setMode('ace/mode/javascript')

filterSession = filterEditor.getSession()

filterEditor.setShowPrintMargin(false)
filterEditor.clearSelection()

filterEditor.renderer.setShowGutter(false)

filterSession.setTabSize(2)
filterSession.setUseSoftTabs(true)
filterSession.setUseWrapMode(true)
filterSession.setWrapLimitRange(null, null)

skipSave = false
##

ICONS =
  unsaved: '.icon-circle-blank'
  saved: '.icon-ok-circle'
  saving: '.icon-spinner'
  locked: '.icon-lock'

$ ->
  setTimeout ->
    # default to selecting the last query
    if ($last = $('.query:last')).length
      skipSave = true
      $last.click()
  , 1

  showIcon = ($icons, iconName) ->
    $icons.children().addClass('display-none')
    $icons.find(ICONS[iconName]).removeClass('display-none')

  addQuery = (data) ->
    queryName = if data.name.length then data.name else "Query #{data.id}"

    $query = "<li class='query' data-content='#{data.content}' data-filter='#{data.filter}' data-name='#{data.name}' data-id='#{data.id}''>#{queryName}.icon-circle-blank</li>"

    $('.queries').append $query

  activeQuery = ->
    $query = $('.query.active')

    return {
      id: $query.data('id')
      name: $query.attr('data-name')
      content: editor.getValue()
      filter: filterEditor.getValue()
    }

  updateQuery = (data) ->
    $query = $('.query.active')

    $query.attr
      'data-name': data.name
      'data-filter': data.filter
      'data-content': data.content

  updateQueryName = (newName) ->
    $('header .title .name').removeClass('display-none').text(newName)
    $('header .title .edit-title').addClass('display-none')

    queryData = activeQuery()
    queryData.name = newName

    $query = findQuery(queryData.id)

    $query.text(newName)
    $query.attr('data-name', newName.trim())

    saveQuery(queryData)

  exportResults = (data, filter) ->
    # export results to the global scope
    # so people can tweak them.
    window.results = data.items
    console.log(results)

    if filter.length
      window.filteredResults = eval(filter)

  displayResultsCount = (data) ->
    $('.sql-results, .filter-results').show()

    $('.sql-results .count').text("#{window.results.length} SQL results returned")

    if window.filteredResults?
      $('.filter-results .count').text("#{window.filteredResults.length} results after applying JavaScript filter")

  resultsTable = (data, filter) ->
    $('.results thead, .results tbody').empty()

    for column in data.columns
      $('table thead').append "<th>#{column}</th>"

    for item in (if window.filteredResults?.length then window.filteredResults else window.results)
      $tr = $('<tr>')

      for key, value of item
        $tr.append "<td>#{value}</td>"

      $('table tbody').append $tr

  findQuery = (id) ->
    $(".query[data-id='#{id}']")

  unsavedChanges = (query) ->
    $query = $('.query.active')
    $icons = $query.next()

    showIcon($icons, 'unsaved')

  saveQuery = (query) ->
    $query = findQuery(query.id)
    $icons = $query.next()

    showIcon($icons, 'saving')

    $.ajax
      type: 'PUT'
      url: "/queries/#{query.id}"
      data:
        content: query.content
        filter: query.filter
        name: query.name
      dataType: 'json'
      success: (data) ->
        showIcon($icons, 'saved')
        updateQuery(data)

  debouncedSaveQuery = _.debounce saveQuery, 300

  editor.on 'change', ->
    unsavedChanges()
    debouncedSaveQuery(activeQuery())

  filterEditor.on 'change', ->
    unsavedChanges()
    debouncedSaveQuery(activeQuery())

  $('.icon-remove').on 'click', ->
    $('.error-message').addClass('display-none')

  $(document).on 'keydown', (e) ->
    return unless e.keyCode is 27

    $('.error-message').addClass('display-none')

  $(document).on 'click', (e) ->
    $target = $(e.target)

    return if $target.closest('.error-message').length

    $('.error-message').addClass('display-none')

  $(document).on 'click', (e) ->
    $target = $(e.target)

    return if $target.is('.title .edit-title, .title h2')
    return if $('.edit-title').is('.display-none')

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
    # save previous query before
    # messing with the active class
    # unless it's during page load
    saveQuery(activeQuery()) unless skipSave

    skipSave = false

    $target = $(e.currentTarget)

    $('.query').removeClass 'active'

    $target.addClass 'active'

    editor.setValue $target.attr('data-content')
    filterEditor.setValue $target.attr('data-filter')

    $('header .title .name').text($target.text())
    $('header .title .edit-title').val($target.text())

  $('.btn-new').on 'click', ->
    queryName = 'New Query'

    $.ajax
      type: 'POST'
      url: '/queries'
      data:
        content: """
/*
Enter your SQL query below.
You can run, save, or delete queries using the buttons above
*/
        """
        filter: """
// Enter your JavaScript filter below.
// Filters modify the returned SQL dataset
// Query results are available for manipulation
// via the global variable `results`. Your filtered
// results will be used to build the report.
// [results[0]]
"""
        name: queryName.trim()
      dataType: 'json'
      success: (data) ->
        addQuery(data)
        $('.query:last').click()

  $('.btn-copy').on 'click', ->
    queryName = $('header .title .name').text()

    $.ajax
      type: 'POST'
      url: '/queries'
      data:
        content: editor.getValue()
        filter: filterEditor.getValue()
        name: if queryName.length then queryName.trim() else 'new query'
      dataType: 'json'
      success: (data) ->
        addQuery(data)
        $('.query:last').click()

  $('.btn-run').on 'click', ->
    $('.query-spinner').removeClass('display-none')

    sql = editor.getValue()

    unless (/limit/i).test(sql)
      editor.setValue(sql + "\nLIMIT #{QUERY_LIMIT}")

    $.ajax
      type: 'GET'
      url: '/run'
      data:
        content: editor.getValue()
      dataType: 'json'
      success: (data) ->
        $('.query-spinner').addClass('display-none')

        exportResults(data, filterEditor.getValue())
        resultsTable(data)
        displayResultsCount(data)
      error: (response) ->
        $('.query-spinner').addClass('display-none')
        try
          {message} = JSON.parse(response.responseText)

          $('.error-message .text').text(message)

          $('.error-message').removeClass('display-none')

  $('.btn-delete').on 'click', ->
    query = activeQuery()

    id = query.id

    $query = findQuery(id)

    queryName = if query.name.length then query.name.trim() else "Query #{id}"

    if confirm "Are you sure you want to delete '#{queryName}'?"
      $.ajax
        type: 'DELETE'
        url: "queries/#{id}"
        dataType: 'json'
        success: ->
          if ($next = $query.next()).length
            $next.addClass 'active'
          else if ($previous = $query.prev()).length
            $previous.addClass 'active'

          $query.remove()
