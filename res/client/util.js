var newerDate = function(date1, date2) {
    return date1 > date2;
};

var timeSince = function(date, currentTime) {
    if (typeof date !== 'object') {
        date = new Date(date);
    }
    if (typeof currentTime === 'undefined') {

        currentTime = new Date();
    }
    else {
        currentTime = new Date(currentTime);
    }
    var seconds = Math.floor((currentTime - date) / 1000);
    var intervalType;
    var interval = Math.floor(seconds / 31536000);
    if (interval >= 1) {
        intervalType = 'year';
    } else {
        interval = Math.floor(seconds / 2592000);
        if (interval >= 1) {
            intervalType = 'month';
        } else {
            interval = Math.floor(seconds / 86400);
            if (interval >= 1) {
                intervalType = 'day';
            } else {
                interval = Math.floor(seconds / 3600);
                if (interval >= 1) {
                    intervalType = "hour";
                } else {
                    interval = Math.floor(seconds / 60);
                    if (interval >= 1) {
                        intervalType = "minute";
                    } else {
                        interval = seconds;
                        intervalType = "second";
                    }
                }
            }
        }
    }
    if (interval > 1 || interval === 0) {
        intervalType += 's';
    }
    return interval + ' ' + intervalType + ' ago';
};

$.fn.scrollView = function (toFocus, isMid) {
    return this.each(function () {
        var scrollTop;
        if (isMid) {
            scrollTop = $(this).offset().top + $(this).height()/2 - $(window).height()/2;
        }
        else {
            scrollTop = $(this).offset().top + $(this).height() - $(window).height();
        }
        $('html, body').animate({
            scrollTop: scrollTop
        }, 500, function() {
            if (toFocus) toFocus.focus();
        });
    });
};

var addS = function(num) {
    return (num === 1) ? '' : 's';
};

var escapeText = function(s) {
    return s
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/'/g, '&apos;')
        .replace(/"/g, '&quot;')
        .replace(/(?:\r\n|\r|\n)/g, ' <br>');
        // .replace(/ /g, '\u00a0');
};
var replaceText = function(s) {
    return s
        .replace(/&amp;/g, '&')
        .replace(/&lt;/g, '<')
        .replace(/&gt;/g, '>')
        .replace(/&apos;/g, '\'')
        .replace(/&quot;/g, '\"')
        .replace(/<br>/g, '\n')
        .replace(/ <br\/>/g, '\n');
};

// takes a text field and an array of strings for autocompletion
var autocomplete = function(input, data) {
  if (input.val().length == input[0].selectionStart && input.val().length == input[0].selectionEnd) {
    var inputArray = input.val().split(' ');
    var val = inputArray[inputArray.length-1].toLowerCase();
    var candidates = [];
    // filter data to find only strings that start with existing value
    for (var i=0; i < data.length; i++) {
      if (data[i].toLowerCase().indexOf(val) === 0 && data[i].length > val.length)
        candidates.push(data[i]);
    }

    if (candidates.length > 0) {
      // some candidates for autocompletion are found
      if (candidates.length === 1) {
        inputArray[inputArray.length-1] = candidates[0];
        input.val(inputArray.join(' '));
      }
      else {
        inputArray[inputArray.length-1] = longestInCommon(candidates, val.length);
        input.val(inputArray.join(' '));
      }
      return true;
    }
  }
  return false;
};

// finds the longest common substring in the given data set.
// takes an array of strings and a starting index
var longestInCommon = function(candidates, index) {
  var i, ch, memo;
  do {
    memo = null;
    for (i=0; i < candidates.length; i++) {
      ch = candidates[i].charAt(index);
      if (!ch) break;
      if (!memo) memo = ch;
      else if (ch != memo) break;
    }
  } while (i == candidates.length && ++index);

  return candidates[0].slice(0, index);
};

var objectToArray = function(obj) {
    return Object.keys(obj).map(function(val) { return obj[val]; });
};
