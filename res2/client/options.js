var optionsList = [];

function handleBeep() {
    if (!audioLoaded) { $('#audio')[0].load(); audioLoaded = true; }
}
function handleHighlight() {
    drawPlayers();
}
function handleHighlightText() {
    if (!JSON.parse(localStorage.highlightText)) {
        $('.chat-highlight').removeClass('chat-highlight');
    }
    else {
        Object.keys(g.textHighlights).forEach(function(id) {
            $('.'+id+'-chat').addClass('chat-highlight');
        });
    }
}
function handleMod() {
    drawLobbyPlayers();
}
function handleTitleNotification() {
}
function handleHideStats() {
    sendAjaxTo({ statsHidden:JSON.parse(localStorage.hideStats) }, 'PUT', '/server/hide')
        .done(function(data) {});
}
function handleBuzz() {
}
function handleOriginalAvatars() {
    drawPlayers();
}
function handleDoubleTabs() {
    if (!JSON.parse(localStorage.doubleTabs)) {
        $('.dynamic-tabs2').addClass('hidden');
        $('.dynamic-tabs').removeClass('dynamic-tabs-adjacent');
    }
    else {
        $('.dynamic-tabs').addClass('dynamic-tabs-adjacent');
        $('.dynamic-tabs').removeClass('hidden');
    }
}
function handleWebsocket() {
    if (JSON.parse(localStorage.websocket)) {
        socket = io.connect();
        socket.on('play', function (data) {
            var handler = handlers[data.cmd];
            if (handler != null) {
                try {
                    handler(data);
                } catch (e) {
                    sendData({ cmd: 'clientCrash', exception:e, msg:data });
                    setTimeout(function() {sendData({cmd:'reconnect'});}, 2000);
                }
            }
        });
        socket.on('disconnect', function() {
            console.log('disconnect');
            socket = null;
        });
    }
    else {
        if (socket) {
            socket.emit('disconn');
        }
    }
}
function handleFontSize() {
    if (JSON.parse(localStorage.fontSize)) {
        $(document.body).css('fontSize', localStorage.getItem('fontSizeValue') + 'px');
    }
    else {
        $(document.body).css('fontSize', options['fontSizeValue'].def + 'px');
    }
}
function handleFontSizeValue() {
    var val = $('#fontSizeValueOption').val();
    if (!(val.length > 0 && $.isNumeric(val))) {
        val = localStorage.getItem('fontSizeValue');
    }
    localStorage.setItem('fontSizeValue', val);
    handleFontSize();
}
function handleDarkTheme() {
    if (JSON.parse(localStorage.darkTheme)) {
        $('body').addClass('dark');
        $('.btn-standard').addClass('btn-inverse');
    }
    else {
        $('body').removeClass('dark');
        $('.btn-standard').removeClass('btn-inverse');
    }
}

var options = {
    "beep": { name: "beep", def: false, handler: handleBeep, type: "checkbox"},
    "highlight": { name: "highlight", def: false, handler: handleHighlight, type: "checkbox"},
    "highlightText": { name: "highlightText", def: false, handler: handleHighlightText, type: "checkbox"},
    "titleNotification": { name: "titleNotification", def: false, handler: handleTitleNotification, type: "checkbox"},
    "hideStats": { name: "hideStats", def: false, handler: handleHideStats, type: "checkbox"},
    "buzz": { name: "buzz", def: true, handler: handleBuzz, type: "checkbox"},
    "originalAvatars": { name: "originalAvatars", def: false, handler: handleOriginalAvatars, type: "checkbox"},
    "mod": { name: "mod", def: false, handler: handleMod, type: "checkbox"},
    "doubleTabs": { name: "doubleTabs", def: false, handler: handleDoubleTabs, type: "checkbox"},
    "websocket": { name: "websocket", def: false, handler: handleWebsocket, type: "checkbox"},
    "fontSize": { name: "fontSize", def: false, handler: handleFontSize, type: "checkbox"},
    "fontSizeValue": { name: "fontSizeValue", def: "14", handler: handleFontSizeValue, type: "number"},
    "darkTheme": { name: "darkTheme", def: false, handler: handleDarkTheme, type: "checkbox"}
};


function initOptions() {

    // Set the checkboxes
    var setCheckbox = function(optionName) {
        setTimeout(function() {
            $('#'+optionName+'Option').prop('checked', JSON.parse(localStorage.getItem(optionName)) ? true : false);
        }, 0);
    };

    // Set the option value
    var setValue = function(optionName) {
        setTimeout(function() {
            $('#'+optionName+'Option').val(localStorage.getItem(optionName));
        }, 0);
    };

    for (var optionName in options) {
        if (!localStorage.getItem(optionName)) {
            localStorage.setItem(optionName, options[optionName].def);
        }
        // Call handlers for each
        options[optionName].handler();
        // Set html and fill optionsList
        if (options[optionName].type === "checkbox") {
            setCheckbox(optionName);
            if (JSON.parse(localStorage.getItem(optionName))) {
                optionsList.push(optionName);
            }
        }
        else if (options[optionName].type === "number") {
            setValue(optionName);
        }
    }

    // Click handlers
    $( '#optionsDropdown a' ).click(function( event ) {

        var $target = $( event.currentTarget ),
           val = $target.attr( 'data-value' ),
           $inp = $target.find( 'input' ),
           idx;

        if ( ( idx = optionsList.indexOf( val ) ) > -1 ) {
          optionsList.splice( idx, 1 );
          setTimeout( function() { $inp.prop( 'checked', false ) }, 0);
          localStorage.setItem(val, false);
        } else {
          optionsList.push( val );
          setTimeout( function() { $inp.prop( 'checked', true ) }, 0);
          localStorage.setItem(val, true);
        }
        options[val].handler();

        $( event.target ).blur();
          
        //console.log( options );
        return false;
        });
    $( '#optionsDropdown a' ).tooltip();

    // Value options
    $('.value-option').click(function(e) {
        e.stopPropagation();
        return false;
        //return false;
    });
    $('.value-option').change(function() {
        var handler = $(this).attr('data-value');
        options[handler].handler();
    });
}

function loadRoleInfo() {
    $.ajax(
        '/server/role', {
        type: 'GET',
        contentType: 'application/json'
        })
    .fail(function(xmlHttpRequest, code, error) {
        setTimeout(function() { loadRoleInfo(); }, 1000);
    })
    .done(function(data) {
        // Save own id
        myId = data.id;
        // Show hidden option in options if user is mod
        if (data.role === 'mod') {
            $('#moditem').removeClass('hidden');
        }
        // Set unclaim button if claimed (hack for if reload in game)
        if (g.highlights3[myId]) {
            onClaim({ id:myId, isClaim:true });
        }
        drawSettings();
    });
}

function loadMutedPlayers() {
    $.ajax(
        '/server/mutes', {
        type: 'GET',
        contentType: 'application/json'
        })
    .fail(function(xmlHttpRequest, code, error) {
    })
    .done(function(data) {
        mutedPlayers = data.names;
    });
}

function initOptionsJS() {
    initOptions();
    // Check if user is a moderator
    loadRoleInfo();

    loadMutedPlayers();

    // Determine window focus for title notification
    $(window).focus(function() {
        windowFocus = true;
        pageTitleNotification.off();
    }).blur(function() {
        windowFocus = false;
    });
}
