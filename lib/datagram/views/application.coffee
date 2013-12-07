QUERY_LIMIT = 100

configureEditor = (selector, options={}) ->
  editor = ace.edit(selector)
  editor.setTheme "ace/theme/tomorrow"
  editor.session.setMode "ace/mode/#{options.language}"

  editor.setShowPrintMargin(false)
  editor.renderer.setShowGutter(false)

  editorSession = editor.getSession()
  editorSession.setTabSize(2)
  editorSession.setUseSoftTabs(true)
  editorSession.setUseWrapMode(true)
  editorSession.setWrapLimitRange(null, null)

  editor

## configure editors
editor = configureEditor "editor",
  language: "sql"

filterEditor = configureEditor "filter-editor",
  language: "javascript"
##

SQL_DEFAULT = """
/*
Enter your SQL query below.
You can run, save, or delete queries using the buttons above
*/
"""

FILTER_DEFAULT = """
// Enter your JavaScript filter below.
// Filters modify the returned SQL dataset
// Query results are available for manipulation
// via the global variable `results`. Your filtered
// results will be used to build the report.
// [results[0]]
"""

ICONS =
  unsaved: '.icon-circle-blank'
  saved: '.icon-ok-circle'
  saving: '.icon-spinner'

$ ->
  setTimeout ->
    # default to selecting the active query
    # this is a hack to load content in the
    # editor
    selectQuery($(".query.active"))
  , 1

  showIcon = ($icons, iconName) ->
    $icons.children().addClass('display-none')
    $icons.find(".icon-lock").removeClass("display-none")
    $icons.find(ICONS[iconName]).removeClass('display-none')

  addQuery = (data) ->
    queryName = if data.name.length then data.name else "Query #{data.id}"

    $query = $("<li class='query' data-content='#{data.content}' data-filter='#{data.filter}' data-name='#{data.name}' data-id='#{data.id}'>#{queryName}</li>")

    $icons = $("<div class='icons'></div>")
    $icons.append $("<div class='icon-lock'></div>"),
      $("<div class='icon-circle-blank display-none'></div>"),
      $("<div class='icon-spinner icon-spin display-none'></div>"),
      $("<div class='icon-ok-circle display-none'></div>")

    $('.queries').append $query
    $('.queries .query:last').after($icons)
    selectQuery($(".query:last"))

  activeQuery = ->
    $query = $(".query.active")

    attrs = {
      id: $query.data('id')
      name: $query.attr('data-name').trim()
      content: editor.getValue()
      filter: filterEditor.getValue()
    }

    if ($lock = $query.next().find(".icon-lock")).is(".locked")
      attrs.locked_at = $lock.data("locked_at")

    attrs

  updateQuery = (data) ->
    $query = $(".query.active")

    $query.attr
      'data-name': data.name
      'data-filter': data.filter
      'data-content': data.content

  updateNameDOM = (newName) ->
    name = newName.trim()

    $('header .title .name').removeClass('display-none').text(name)
    $('header .title .edit-title').addClass('display-none').val(name)

    queryData = activeQuery()

    $query = findQuery(queryData.id)

    $query.text(name)
    $query.attr('data-name', name)

  updateQueryName = (newName) ->
    updateNameDOM(newName)

    queryData = activeQuery()
    queryData.name = newName.trim()

    saveQuery(queryData)

  exportResults = (data, filter) ->
    # export results to the global scope
    # so people can tweak them.
    window.results = data.items
    console.log(results)

    window.filteredResults = eval(filter) if filter.length

  displayResultsCount = (data) ->
    $('.sql-results, .filter-results').show()

    $('.sql-results .count').text("#{window.results.length} SQL results returned")

    if window.filteredResults?
      $('.filter-results .count').text("#{window.filteredResults.length} results after applying JavaScript filter")

  downloadPath = (query) ->
    "/queries/#{query.id}/download"

  renderTable = (collection, columns) ->
    query = activeQuery()

    $('.btn.download')
      .removeAttr('disabled')
      .attr('href', downloadPath(query))

    for column in columns
      $('table thead').append "<th>#{column}</th>"

    for item in collection
      $tr = $('<tr>')

      for key, value of item
        $tr.append "<td>#{value}</td>"

      $('table tbody').append $tr

  resultsTable = (data, filter) ->
    $('.results thead, .results tbody').empty()

    if window.filteredResults?.length
      renderTable(filteredResults, _.keys(window.filteredResults[0]))
    else if window.results?.length
      renderTable(results, data.columns)

  findQuery = (id) ->
    $(".query[data-id='#{id}']")

  unsavedChanges = (query) ->
    $query = $('.query.active')
    $icons = $query.next()

    showIcon($icons, 'unsaved')

  copyQuery = ->
    query = activeQuery()

    $.ajax
      type: 'POST'
      url: '/queries'
      data: query
      dataType: 'json'
      success: addQuery

  saveQuery = (query) ->
    $query = findQuery(query.id)
    $icons = $query.next()

    showIcon($icons, 'saving')

    $.ajax
      type: 'PUT'
      url: "/queries/#{query.id}"
      data: query
      dataType: 'json'
      success: (data) ->
        showIcon($icons, 'saved')
        updateQuery(data)

  selectQuery = ($query) ->
    $('.query').removeClass 'active'

    $query.addClass 'active'

    editor.setValue $query.attr('data-content')
    filterEditor.setValue $query.attr('data-filter')

    updateNameDOM($query.text().trim())

    # poor man's bookmarkability
    history?.pushState?({}, "#{$query.attr('data-name')}", "/queries/#{$query.attr('data-id')}")

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
    saveQuery(activeQuery())
    selectQuery($(e.currentTarget))

  $('.btn-new').on 'click', ->
    $.ajax
      type: 'POST'
      url: '/queries'
      data:
        content: SQL_DEFAULT
        filter: FILTER_DEFAULT
        name: "New Query"
      dataType: 'json'
      success: addQuery

  $('.btn-copy').on 'click', copyQuery

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

  $('.btn-schema').on 'click', ->
    $('.schema-overlay').removeClass 'display-none'

    $('.schema').isotope
      itemSelector: '.database-table'
      masonry:
        columnWidth: 1
      masonryHorizontal:
        rowHeight: 1

  $('.schema-overlay .icon-remove-sign').on 'click', ->
    $('.schema-overlay').addClass 'display-none'

  $(".icon-lock").on "click", ->
    $this = $(this)

    if $this.is(".locked")
      $this.removeClass("locked")
      $this.data("locked_at", null)
    else
      d = new Date
      $this.addClass("locked")
      $this.data("locked_at", d)
      $this.attr("title", "Locked from modifications at #{d.toLocaleString()}")

    selectQuery($this.parent().prev())
    saveQuery(activeQuery())

  $('.btn-delete').on 'click', ->
    query = activeQuery()

    id = query.id

    $query = findQuery(id)

    queryName = if query.name.length then query.name else "Query #{id}"

    if confirm "Are you sure you want to delete '#{queryName}'?"
      $.ajax
        type: 'DELETE'
        url: "/queries/#{id}"
        dataType: 'json'
        success: ->
          if ($next = $query.nextAll('.query:first')).length
            $next.addClass 'active'
          else if ($previous = $query.prevAll('.query:first')).length
            $previous.addClass 'active'

          $query.next().remove() # icons element
          $query.remove()
