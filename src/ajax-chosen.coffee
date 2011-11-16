(($) ->
 $.fn.ajaxChosen = (options, itemBuilder) ->

    defaultedOptions = {
      minLength: 3,
      queryParameter: 'term',
      queryLimit: 10,
      data: {}
    }

    if defaultedOptions.userSuppliedSuccess
      defaultedOptions.userSuppliedSuccess = defaultedOptions.success

    $.extend(defaultedOptions, options)

    # determining whether this allows
    # multiple results will affect both the selector
    # and the ways previously selected results are cleared (line 88) 
    multiple = this.attr('multiple')?
    if multiple
      inputSelector = ".search-field > input"
    else
      inputSelector = ".chzn-search > input"

    # grab a reference to the select box
    select = this

		#initialize chosen
    this.chosen()

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

          # Checking minimum search length and dupliplicate value searches
          # to avoid excess ajax calls.
          return false if val.length < defaultedOptions.minLength or val is prevVal

          #grab the items that are currently in the matching field list
          currentOptions = select.find('option')

          #if there are fewer than 10 of these and we're making a longer
          #query, we can let regular chosen handle the filtering
          #provided that we've already done at least one call
          if currentOptions.length < defaultedOptions.queryLimit and
             val.indexOf(prevVal) is 0 and
             prevVal isnt ''
            return false

          #grab a reference to the input field
          field = $(this)

          #add the search parameter to the ajax request data
          defaultedOptions.data[defaultedOptions.queryParameter] =  val

          # If the user provided an ajax success callback, store it so we can
          # call it after our bootstrapping is finished.
          userDefinedSuccess = defaultedOptions.success

          # Create our own success callback
          defaultedOptions.success = (data) ->
            # Send the ajax results to the user itemBuilder so we can get an object of
            # value => text pairs
            items = itemBuilder data

            # use value => text pairs to build <option> tags
            newOptions = []
            #TODO: can this use DO block coffee script syntax?
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
            #this is to grab the 
            latestVal = field.val()

            # Tell chosen that the contents of the <select> input have been updated
            # This makes chosen update its internal list of the input data.
            select.trigger "liszt:updated"

            # Chosen contents of the input field get removed once you
            # call trigger above so we add the value the user was typing back into
            # the input field.
            #
            field.val(latestVal)

            # Finally, call the user supplied callback (if it exists)
            if defaultedOptions.userSuppliedSuccess
              defaultedOptions.userSuppliedSuccess(data) 

            #end of success function

          # Execute the ajax call to search for autocomplete data
          $.ajax(defaultedOptions)

          #end of search function
        this.previousSearch = setTimeout(search, 100);


)(jQuery)
