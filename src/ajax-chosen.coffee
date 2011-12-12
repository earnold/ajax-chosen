(($) ->
 $.fn.ajaxChosen = (options, itemBuilder) ->

    defaultedOptions = {
      minLength: 3,
      queryParameter: 'term',
      queryLimit: 10,
      data: {},
      chosenOptions: {},
      searchingText: "Searching...",
      noresultsText: "No results."
    }


    $.extend(defaultedOptions, options)

    #because we define the success callback for each
    #search we need to store the user supplied success
    if defaultedOptions.success
      defaultedOptions.userSuppliedSuccess = defaultedOptions.success

    
    #by design, chosen only has one state for when you 
    #don't have matching items: No Results. 
    #However, we need two states, searching
    #and no results. 
    #
    #TODO: you accidentally lose any user definied no_results_test
    defaultedOptions.chosenOptions.no_results_text = defaultedOptions.searchingText

    # determining whether this allows
    # multiple results will affect both the selector
    # and the ways previously selected results are cleared (line 88) 
    multiple = this.attr('multiple')?
    
    #the box where someone types has a different selector 
    #based on the type
    if multiple
      inputSelector = ".search-field > input"
    else
      inputSelector = ".chzn-search > input"

    # grab a reference to the select box
    select = this

		#initialize chosen
    this.chosen(defaultedOptions.chosenOptions)

    # Now that chosen is loaded normally, we can attach 
    # a keyup event to the input field.
    this.next('.chzn-container')
      .find(inputSelector)
      .bind 'keyup', (e)->

        #we wrap our search in a short Timeout so that if
        #a person is typing we do not get race conditions with
        #multiple searches happening simultaneously
        if this.previousSearch
          clearTimeout(this.previousSearch) 

        #wrap the search functionality in a function
        #so that it can be put inside a timeout
        search = => 
          # Retrieve the current value of the input form
          val = $.trim $(this).attr('value')

          # Retrieve the previous value of the input form
          prevVal = $(this).data('prevVal') ? ''

          # store the current value in the element
          $(this).data('prevVal', val)

         #grab a reference to the input field
          field = $(this)

          #our hack above changes the No Results text to 'Searching...'
          #we should change it back in the case there are no results
          #within a native chosen search
          clearSearchingLabel = =>
              if multiple
                resultsDiv = field.parent().parent().siblings()
              else
                resultsDiv = field.parent().parent()
              #chosen does a fancy regex when matching, so 
              #we use the raw field value (e.g. not trimmed)
              #in case it's terminal spaces preventing the match
              resultsDiv.find('.no-results').html(defaultedOptions.noresultsText + " '" + $(this).attr('value') + "'")


          # Checking minimum search length and dupliplicate value searches
          # to avoid excess ajax calls.
          if val.length < defaultedOptions.minLength or val is prevVal
            clearSearchingLabel()
            return false;

          #grab the items that are currently in the matching field list
          currentOptions = select.find('option')

          #if there are fewer than 10 of these and we're making a longer
          #query, we can let regular chosen handle the filtering
          #provided that we've already done at least one call
          if currentOptions.length < defaultedOptions.queryLimit and
                val.indexOf(prevVal) is 0 and
                prevVal isnt ''
              clearSearchingLabel()
              return false

          #add the search parameter to the ajax request data
          defaultedOptions.data[defaultedOptions.queryParameter] =  val

          # Create our own success callback
          defaultedOptions.success = (data) ->

            #note: sometimes a person will leave the input
            #      before success happens. In this case, jettison the results
            #
            return unless field.is(':focus')

            # Send the ajax results to the user itemBuilder so we can get an object of
            # value => text pairs
            items = itemBuilder data

            # use value => text pairs to build <option> tags
            newOptions = []

            $.each items, (value, text) ->
              newOpt = $('<option>')
              newOpt.attr('value', value).html(text)
              newOptions.push $(newOpt)

            #remove any of the current options that aren't in the the 
            #new options block 
            for currentOpt in currentOptions
              do (currentOpt) -> 
                $currentOpt = $(currentOpt)
                return if $currentOpt.attr('selected') and multiple
                presenceInNewOptions = (newOption for newOption in newOptions when newOption.attr('value') is $currentOpt.attr('value'))
                if presenceInNewOptions.length is 0
                  $currentOpt.remove()

            #get the new, trimmed currentOptions
            #so the next loop doesn't do unnecessary loops
            currentOptions = select.find('option')

            # select.append newOption for newOption in newOptions
            for newOpt in newOptions
              do (newOpt) ->
                presenceInCurrentOptions = false
                for currentOption in currentOptions
                  do (currentOption) -> 
                    if $(currentOption).attr('value') is newOpt.attr('value')
                      presenceInCurrentOptions = true
                if !presenceInCurrentOptions
                  select.append newOpt

            #even with setting call backs, we may
            #get race conditions on a search
            #this is to fix that
            latestVal = field.val()

            #this may seem to come late, but... 
            #if we actually have found nothing on the server, 
            #we display a custom no results tag
             #if there are no results on the server
            #add a no results tag. 
            if $.isEmptyObject(data)
              noResult = $('<option>')
              noResult.addClass('no-results')
              noResult.html(defaultedOptions.noresultsText + " '" + latestVal + "'").attr('value', '')
              select.append(noResult)
            else
              select.change()


            # Tell chosen that the contents of the <select> input have been updated
            # This makes chosen update its internal list of the input data.
            select.trigger "liszt:updated"

            #our hack no-result classes will have too many
            #classes associated with them, so those must be removed
            $('.no-results').removeClass('active-result')

            # Chosen contents of the input field get removed once you
            # call trigger above so we add the value the user was typing back into
            # the input field.
            #
            field.val(latestVal)

            if !$.isEmptyObject(data) 
              #to mimic the chosen winnowing behavior, 
              #we highlight the first result with a keydown event
              keydownEvent = $.Event('keydown')
              keydownEvent.which = 40 #the down arrow
              field.trigger(keydownEvent)


            # Finally, call the user supplied callback (if it exists)
            if defaultedOptions.userSuppliedSuccess
              defaultedOptions.userSuppliedSuccess(data) 

            #end of success function

          # Execute the ajax call to search for autocomplete data
          $.ajax(defaultedOptions)

          #end of search function
        this.previousSearch = setTimeout(search, 100);


)(jQuery)
