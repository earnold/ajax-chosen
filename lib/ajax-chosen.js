(function() {
  (function($) {
    return $.fn.ajaxChosen = function(options, callback) {
      var select, selector;
      select = this;
      this.chosen();
      if (this.attr('multiple') != null) {
        selector = ".search-field > input";
      } else {
        selector = ".chzn-search > input";
      }
      return this.next('.chzn-container').find(selector).bind('keyup', function() {
        var field, val, _ref;
        val = $.trim($(this).attr('value'));
        if ((_ref = options.minLength) == null) {
          options.minLength = 3;
        }
        if (val.length < options.minLength || val === $(this).data('prevVal')) {
          return false;
        }
        $(this).data('prevVal', val);
        field = $(this);
        options.data = {
          term: val
        };
        if (typeof success === "undefined" || success === null) {
          success = options.success;
        }
        options.success = function(data) {
          var items;
          if (!(data != null)) {
            return;
          }
          select.find('option').each(function() {
            if (!$(this).is(":selected")) {
              return $(this).remove();
            }
          });
          items = callback(data);
          $.each(items, function(value, text) {
            return $("<option />").attr('value', value).html(text).appendTo(select);
          });
          select.trigger("liszt:updated");
          field.attr('value', val);
          if (typeof success !== "undefined" && success !== null) {
            return success();
          }
        };
        return $.ajax(options);
      });
    };
  })(jQuery);
}).call(this);
