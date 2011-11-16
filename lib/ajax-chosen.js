(function() {
  (function($) {
    return $.fn.ajaxChosen = function(options, itemBuilder) {
      var defaultedOptions, inputSelector, multiple, select;
      defaultedOptions = {
        minLength: 3,
        queryParameter: 'term',
        queryLimit: 10,
        data: {}
      };
      $.extend(defaultedOptions, options);
      multiple = this.attr('multiple') != null;
      if (multiple) {
        inputSelector = ".search-field > input";
      } else {
        inputSelector = ".chzn-search > input";
      }
      select = this;
      this.chosen();
      return this.next('.chzn-container').find(inputSelector).bind('keyup', function(e) {
        var currentOptions, field, prevVal, userDefinedSuccess, val, _ref;
        val = $.trim($(this).attr('value'));
        prevVal = (_ref = $(this).data('prevVal')) != null ? _ref : '';
        if (val.length < defaultedOptions.minLength || val === prevVal) {
          return false;
        }
        $(this).data('prevVal', val);
        currentOptions = select.find('option');
        if (currentOptions.length < defaultedOptions.queryLimit && val.indexOf(prevVal) === 0 && prevVal !== '') {
          return false;
        }
        field = $(this);
        defaultedOptions.data[defaultedOptions.queryParameter] = val;
        userDefinedSuccess = defaultedOptions.success;
        defaultedOptions.success = function(data) {
          var currentOpt, items, latestVal, newOpt, newOptions, _fn, _fn2, _i, _j, _len, _len2;
          items = itemBuilder(data);
          newOptions = [];
          $.each(items, function(value, text) {
            var newOpt;
            newOpt = $('<option>');
            newOpt.attr('value', value).html(text);
            return newOptions.push($(newOpt));
          });
          _fn = function(currentOpt) {
            var $currentOpt, newOption, presenceInNewOptions;
            $currentOpt = $(currentOpt);
            if ($currentOpt.attr('selected') && multiple) {
              return;
            }
            presenceInNewOptions = (function() {
              var _j, _len2, _results;
              _results = [];
              for (_j = 0, _len2 = newOptions.length; _j < _len2; _j++) {
                newOption = newOptions[_j];
                if (newOption.attr('value') === $currentOpt.attr('value')) {
                  _results.push(newOption);
                }
              }
              return _results;
            })();
            if (presenceInNewOptions.length === 0) {
              return $currentOpt.remove();
            }
          };
          for (_i = 0, _len = currentOptions.length; _i < _len; _i++) {
            currentOpt = currentOptions[_i];
            _fn(currentOpt);
          }
          currentOptions = select.find('option');
          _fn2 = function(newOpt) {
            var currentOption, presenceInCurrentOptions, _fn3, _k, _len3;
            presenceInCurrentOptions = false;
            _fn3 = function(currentOption) {
              if ($(currentOption).attr('value') === newOpt.attr('value')) {
                return presenceInCurrentOptions = true;
              }
            };
            for (_k = 0, _len3 = currentOptions.length; _k < _len3; _k++) {
              currentOption = currentOptions[_k];
              _fn3(currentOption);
            }
            if (!presenceInCurrentOptions) {
              return select.append(newOpt);
            }
          };
          for (_j = 0, _len2 = newOptions.length; _j < _len2; _j++) {
            newOpt = newOptions[_j];
            _fn2(newOpt);
          }
          latestVal = field.attr('value');
          select.trigger("liszt:updated");
          field.attr('value', latestVal);
          if (userDefinedSuccess != null) {
            return userDefinedSuccess(data);
          }
        };
        return $.ajax(defaultedOptions);
      });
    };
  })(jQuery);
}).call(this);
