var debugLog = [];

var cardNames = {
    NoConfidence: 'No Confidence',
    KeepingCloseEye: 'Keeping a Close Eye on You',
    StrongLeader: 'Strong Leader',
    InTheSpotlight: 'In the Spotlight',

    OpenUp: 'Open Up',
    EstablishConfidence: 'Establish Confidence',
    Overheard: 'Overheard',
    TakeResponsibility: 'Take Responsibility',
    OpinionMaker: 'Opinion Maker',
    LadyOfTheLake: 'Lady of the Lake',
    Inquisitor: 'Inquisitor'
};

var g;
var resetGlobals = function() {
    var lobbyPlayers = (g && g.lobbyPlayers) ? g.lobbyPlayers : {};
    g = {
        lobbyPlayers: {},
        status: '',
        msgs: [],
        choices: [],
        choiceIdx: 0,
        players: [],
        cards: [],
        votes: {},
        gamelogs: [],
        gamelogIdx: 0,
        highlights: {},
        highlights2: {},
        highlights3: {},
        textHighlights: {},
        guns: [],
        investigator: null,
        excalibur: null,
        games: [],
        votelog: { rounds:[0,0,0,0,0], approve:[], reject:[], onteam:[], leader:[], investigator:[], excalibur:[], excalibured:[]},
        scoreboard: {},
        settings: { anonMode: false, anonCategory: 'color' }
    };
    g.lobbyPlayers = lobbyPlayers;
}
resetGlobals();

var leaderOffsetX = 55;
var leaderOffsetY = 60;
var gunsOffsetX = 5;
var gunsOffsetY = 40;
var investigatorOffsetX = 7;
var excaliburOffsetX = 5;
var excaliburOffsetY = 10;

var myId = null;
var audioLoaded = false;
var canBuzz = true;
var pollNum = 0;
var mutedPlayers = [];

var socket;

// User input handlers
var onJoinGame = function(id) {
    // load audio to fix iOS needing a click to play audio
    if (!audioLoaded) { $('#audio')[0].load(); audioLoaded = true; }
    sendData({ cmd:'join', id:id });
}

var onCreateGame = function(type, isRanked, special) {
    return function() {
        // load audio to fix iOS needing a click to play audio
        if (!audioLoaded) { $('#audio')[0].load(); audioLoaded = true; }
        sendData({ cmd:'join', gameType:type, isRanked:isRanked, special:special });
    }
}

var onLeaveGame = function() {
    sendData({ cmd:'leave' });
}

var onEnter = function(cmd) {
    return function(event) {
        if (event.keyCode === 13) {
            if (event.target.value != '') {
                sendData({ cmd:cmd, msg:event.target.value });
                event.target.value = '';
            }
            event.preventDefault();
        }
        
    };
}

var onDismissMsg = function() {
    if (g.ignoreClicks) {
        return;
    }
    g.msgs.shift();
    drawMsgArea();
}

var onDismissChoose = function(response) {
    var question = g.choices[g.choiceIdx];
    var isCancelled = question.canCancel && response.length === 0;
    if (!isCancelled &&
        question.cmd === 'choosePlayers' &&
        response.length !== question.n) {
        return;
    }
    sendData({ cmd:question.cmd, choiceId:question.choiceId, choice:response });
    g.choices.splice(g.choiceIdx, 1);
    g.choiceIdx = g.choiceIdx % g.choices.length;
    if (g.choices.length === 0) {
        g.choiceIdx = 0;
    }
    g.highlights = {};
    drawMsgArea();
    drawPlayers();
}

var onNextChoice = function() {
    g.choiceIdx = (g.choiceIdx + 1) % g.choices.length;
    g.highlights = {};
    drawMsgArea();
    drawPlayers();
}

var onClickUserTile = function(id) {
    return function(event) {
        if (g.choices.length > 0 &&
            g.choices[g.choiceIdx].cmd === 'choosePlayers')
        {
            if (g.choices[g.choiceIdx].players == null ||
                g.choices[g.choiceIdx].players.indexOf(id) >= 0) {
                g.highlights[id] = !g.highlights[id];
                drawPlayers();
                drawMsgArea();
            }
        }
        else {
            if (localStorage.highlight && JSON.parse(localStorage.highlight)) {
                g.highlights2[id] = !g.highlights2[id];
                drawPlayers();
                drawMsgArea();
            }
        }
    }
}

var onClickUserName = function(id) {
    return function(event) {
        if (localStorage.highlightText && JSON.parse(localStorage.highlightText)) {
            g.textHighlights[id] = !g.textHighlights[id];
            if (g.textHighlights[id]) {
                $('.'+id+'-chat').addClass('chat-highlight');
            }
            else {
                $('.'+id+'-chat').removeClass('chat-highlight');
            }
        }
    }
}

var onNextGameLog = function() {
    g.gamelogIdx = Math.min(Math.max(g.gamelogs.length - 1, 0), g.gamelogIdx + 1);
    drawGameLog();
}

var onPrevGameLog = function() {
    g.gamelogIdx = Math.max(0, g.gamelogIdx - 1);
    drawGameLog();
}

var onClickClaim = function(isClaim) {
    return function() {
        sendData({ cmd:'claim', isClaim:isClaim });
    }
}

var onClickPoll = function() {
    return function() {
        pollNum++;
        pollLoop();
    }
}

var onClickRoleChoice = function(cancel) {
    return function(e) {
        e.preventDefault();
        var role = $(this).html();
        sendData({ cmd: 'chooseRole', role: role, cancel: cancel });
    }
}

var onClickSettings = function() {
    $("#settings-dialog").dialog("open");
}

var onClickSetting = function() {
    return function() {
        sendData({ cmd: 'setting', setting: { name:$(this).attr('data-name'), value: $(this).prop( "checked" ) } });
    }
}

var onChangeSetting = function() {
    return function() {
        var name = $(this).attr('data-name');
        var value = $(this).val();
        if (g.settings[name] !== value) {
            sendData({ cmd: 'setting', setting: { name: $(this).attr('data-name'), value: $(this).val() } });
        }
    }
}

// Server message handlers
var onJoin = function() {
    $("#game-container").removeClass("hidden");
    $("#lobby-container").addClass("hidden");

    resetGlobals();
    drawPlayers();
    drawMsgArea();
    drawGameLog();
    drawGuns();
    drawInvestigator();
    drawExcalibur();
    drawSettings();
    $('#scoreboard').html('');
    $('.chat-text').html('<div class=current></div>');

    $(".choose-role").removeClass("hidden");
    $(".choose-role-desc").addClass("hidden");
    $(".cancel-choose-role").addClass("hidden");
}

var onLeave = function() {
    var isDiscussionContainer = $('.content-container').not('.hidden').first().attr('id') === 'discussion-container';
    if (isDiscussionContainer) {
        previousActiveContainer = $('#lobby-container');
    }
    else {
        $("#game-container").addClass('hidden');
        $("#lobby-container").removeClass('hidden');
    }
    drawGames();
}

var onChat = function(data) {
    if (data.isSpectator && $('#mute-spectators').prop('checked')) {
        return;
    }
    if (isMuted(data.player) && !(inGame(getId(data.player)) && inGame(myId))) {
        return;
    }
    updateChat($('.chat-text'), data);
    highlightTab('#chat-nav-tab');
}

var onAllChat = function(data) {
    if ( isMuted(data.player) && !(inGame(getId(data.player)) && inGame(myId)) ) {
        return;
    }
    updateChat($('#lobby-chat-text'), data);
    updateChat($('.all-chat-text'), data);
    if (!$('#game-container').hasClass('hidden')) {
        highlightTab('#all-chat-nav-tab');
    }
}

var onStatus = function(data) {
    g.status = data.msg;
    
    // Don't refresh the msg area if choices are up ... we may 
    // accidentally close a dropdown if we do.
    if (g.choices.length === 0) {
        drawMsgArea();
    }
}

var onMsg = function(data) {
    if (g.msgs.length === 0) {
        g.ignoreClicks = true;
        setTimeout(function() { g.ignoreClicks = false; }, 300);
    }
    g.msgs.push(data.msg);
    drawMsgArea();
}

var onChoose = function(data) {
    for (var idx = 0; idx < g.choices.length; ++idx) {
        if (g.choices[idx].choiceId === data.choiceId) {
            g.choices[idx] = data;
            drawMsgArea();
            return;
        }
    }
    g.choices.push(data);
    drawMsgArea();
    if (data.cmd === 'chooseTakeCard') {
        drawPlayers();
    }
}

var onCancelChoose = function(data) {
    for (var idx = 0; idx < g.choices.length; ++idx) {
        if (g.choices[idx].choiceId === data.choiceId) {
            if (idx == g.choiceIdx) {
                g.highlights = {};
                if (g.choiceIdx > 0) {
                    --g.choiceIdx;
                }
            }
            g.choices.splice(idx, 1);
            drawMsgArea();
            return;
        }
    }
}

var onLeader = function(data) {
    g.leader = data.player;
    var p = $('#player' + g.leader).position();
    $('#leader-star').animate({
        left: p.left + leaderOffsetX,
        top: p.top + leaderOffsetY,
    }, null, null, drawPlayers);
    
    g.votelog.leader[g.votelog.leader.length - 1] = g.leader;
    drawVoteLog();
}

var onPlayers = function(data) {
    // Notifications
    if (g.players && data.players.length > g.players.length && g.players.length != 0) {
        if (localStorage.beep && JSON.parse(localStorage.beep)) {
            $('#audio')[0].play();
        }
        if (localStorage.titleNotification && JSON.parse(localStorage.titleNotification) && !windowFocus) {
            pageTitleNotification.off();
            pageTitleNotification.on("("+data.players.length+") players", 1000);
        }
    }

    g.players = data.players;
    for (var i = 0; i < g.players.length; ++i) {
        g.players[i].name = xmlEscape(g.players[i].name);
    }

    if (!g.players.some(function(p) { return p.id === g.leader })) {
        delete g.leader;
    }
    
    if (g.players.length > 0) {
        g.leader = g.leader || g.players[0].id;
    }
        
    drawPlayers();
    drawVoteLog();
    drawSettings();

}

var onScoreboard = function(data) {
    g.scoreboard = data;
    
    var html = "";
    for (var i = 0; i < data.missionTeamSizes.length; ++i) {
        var color = 
            data.score[i] === true ? " btn-primary" :
            data.score[i] === false ? " btn-danger" : "";
        html +=
            "<button class='btn disabled" + color + "' style='width:40px'>" +
                data.missionTeamSizes[i] +
                (data.failuresRequired[i] > 1 ? "*" : "") +
            "</button> ";
    }
    html += "<p></p>Failed votes:" + (data.round - 1);
    $('#scoreboard').html(html);
    
    if (data.round <= 5 && g.votelog.rounds[data.mission - 1] !== data.round) {
        g.votelog.rounds[data.mission - 1] = data.round;
        g.votelog.leader.push(g.leader);
        g.votelog.approve.push([]);
        g.votelog.reject.push([]);
        g.votelog.onteam.push([]);
        g.votelog.investigator.push(null);
        g.votelog.excalibur.push(null);
        g.votelog.excalibured.push(null);
        drawVoteLog();
    }
}

var onAddCard = function(data) {
    g.cards.push(data);
    drawPlayers();
}

var onSubCard = function(data) {
    for (var i = 0; i < g.cards.length; ++i) {
        if (g.cards[i].player === data.player &&
            g.cards[i].card   === data.card) {
            g.cards.splice(i, 1);
            return drawPlayers();
        }
    }
}

var onAddVote = function(data) {
    g.votes[data.player] = data.vote;
    drawPlayers();
    
    if (data.vote === 'Approve') {
        g.votelog.approve[g.votelog.approve.length - 1].push(data.player);
    } else {
        g.votelog.reject[g.votelog.reject.length - 1].push(data.player);
    }
    drawVoteLog();
}

var onSubVote = function(data) {
    g.votes = {};
    drawPlayers();
}

var onGameLog = function(data) {
    var page = 'Mission ' + data.mission + ', round ' + data.round;
    if (g.gamelogs.length === 0 ||
        g.gamelogs[g.gamelogs.length - 1].page !== page) {
        g.gamelogs.push({ page:page, text:'' });
    }
    g.gamelogs[g.gamelogs.length - 1].text += '<br>' + xmlEscape(data.msg);
    drawGameLog();
    drawSettings();
}

var onGuns = function(data) {
    g.guns = data.players;
    drawGuns();
    for (var i = 0; i < g.guns.length; ++i) {
        var pos = $('#player' + g.guns[i]).position();
        $('#gun' + i).animate({ top: pos.top + gunsOffsetY, left: pos.left + gunsOffsetX });
    }
    
    if (g.guns.length > 0) {
        g.votelog.onteam[g.votelog.onteam.length - 1] = data.players;
        drawVoteLog();
    }
}

var onInvestigator = function(data) {
      g.investigator = data.player;
      drawInvestigator();
      if(g.investigator !== null) { 
          var p = $('#player' + g.investigator).position();
          $('#investigator-mark').animate({
              left: p.left + investigatorOffsetX,
              top: p.top,
          });
          
          g.votelog.investigator[g.votelog.investigator.length - 1] = g.investigator;
          drawVoteLog();
      }
}

var onExcalibur = function(data) {
      g.excalibur = data.player;
      drawExcalibur();
      if(g.excalibur !== null) {
          var p = $('#player' + g.excalibur).position();
          $('#excalibur-mark').animate({
              left: p.left + excaliburOffsetX,
              top: p.top + excaliburOffsetY,
          });
          
          g.votelog.excalibur[g.votelog.excalibur.length - 1] = g.excalibur;
          drawVoteLog();
      }
}

var onExcalibured = function(data) {
    g.votelog.excalibured[g.votelog.excalibured.length - 1] = data.player;
    drawVoteLog();
}

var onAddGame = function(data) {
    for (var i = 0; i < g.games.length; ++i) {
        if (g.games[i].id === data.id) {
            g.games[i].msg = data.msg;
            drawGames();
            return;
        }
    }
    
    g.games.push(data);
    drawGames();
}

var onSubGame = function(data) {
    g.games = g.games.filter(function(i) { return i.id !== data.id });
    drawGames();
}

var onVoteLog = function(data) {
    g.votelog = data;
    drawVoteLog();
}

var onAddPlayer = function(data) {
    g.lobbyPlayers[data.id] = data.name;
    drawLobbyPlayers();
}

var onSubPlayer = function(data) {
    delete g.lobbyPlayers[data.id];
    drawLobbyPlayers();
}

var onClaim = function(data) {
    g.highlights3[data.id] = data.isClaim;
    drawPlayers();
    drawClaimButton();
}

var onReconnect = function() {
    // $("#game-container").removeClass("hidden");
    // $("#lobby-container").addClass("hidden");
    resetGlobals();
    drawPlayers();
    drawMsgArea();
    drawGameLog();
    drawGuns();
    drawInvestigator();
    drawExcalibur();
    $('#scoreboard').html('');
    //$('#chat-text').html('<div class=current></div>');
}

var onBuzz = function(data) {
    if (localStorage.buzz && JSON.parse(localStorage.buzz) && canBuzz) {
        canBuzz = false;
        if (localStorage.beep && JSON.parse(localStorage.beep)) {
            $('#audio')[0].play();
        }
        if (localStorage.titleNotification && JSON.parse(localStorage.titleNotification) && !windowFocus) {
            pageTitleNotification.off();
            pageTitleNotification.on(""+data.player+" has " + data.buzzType + " you", 1000);
        }
        onAllChat({ player:'server', isPrivate: true, msg: data.player + " has " + data.buzzType + " you." });
        setTimeout(function() { canBuzz = true; }, 15000);
        sendData({ cmd:'allChat', msg:"/answerbuzz " + data.questionId + " success" });
    }
    else if (!canBuzz) {
        sendData({ cmd:'allChat', msg:"/answerbuzz " + data.questionId + " recent" });
    }
    else {
        sendData({ cmd:'allChat', msg:"/answerbuzz " + data.questionId + " notification" });
    }
}

var onRoleChosen = function(data) {
    if (data.canChoose) {
        $(".choose-role-group").removeClass("hidden");
    }
    else if (data.canChoose !== undefined) {
        $(".choose-role-group").addClass('hidden');
    }
    if (data.used) {
        $(".choose-role").addClass("hidden");
        $(".choose-role-desc").html(data.desc);
        $(".choose-role-desc").removeClass("hidden");
        if (data.isMe) {
            $(".cancel-choose-role").removeClass("hidden");
        }
    }
    else {
        $(".choose-role").removeClass("hidden");
        $(".choose-role-desc").addClass("hidden");
        $(".cancel-choose-role").addClass("hidden");
    }
    if (data.numTokens !== undefined) {
        $("#role-token-number").html(data.numTokens);
    }
}

var onMute = function(data) {
    sendAjaxTo({}, 'GET', 'server/mutes')
        .done(function(data) {
            mutedPlayers = data.names;
        })
}

var onSetting = function(data) {
    g.settings[data.name] = data.value;
    drawSettings();
}

var handlers = {
    'join': onJoin,
    'leave': onLeave,
    'chat': onChat,
    'allChat': onAllChat,
    'status': onStatus,
    'msg': onMsg,
    'choose': onChoose,
    'choosePlayers': onChoose,
    'chooseTakeCard': onChoose,
    'cancelChoose': onCancelChoose,    
    'leader': onLeader,
    'players': onPlayers,
    'scoreboard': onScoreboard,
    '+card': onAddCard,
    '-card': onSubCard,
    '+vote': onAddVote,
    '-vote': onSubVote,
    'gamelog': onGameLog,
    'guns': onGuns,
    'investigator': onInvestigator,
    'excalibur': onExcalibur,
    'excalibured': onExcalibured,
    '+game': onAddGame,
    '-game': onSubGame,
    'votelog': onVoteLog,
    '+player': onAddPlayer,
    '-player': onSubPlayer,
    'claim': onClaim,
    'reconnect':onReconnect,
    'buzz': onBuzz,
    'chooseRole': onRoleChosen,
    'mute': onMute,
    'setting': onSetting
};

var drawGames = function() {
    var html = '';
    var gameTypeNames = {
        1: 'Original',
        2: 'Avalon',
        3: 'Basic',
        5: 'Hunter'
    };
    var isRankedNames = {
        true: 'Ranked',
        false: 'Unranked'
    };
    for (var i = 0; i < g.games.length; ++i) {
        html += 
            '<tr onclick="onJoinGame(' + g.games[i].id + ')">' +
                '<td>' + g.games[i].id + '</td>' +
                '<td>' + g.games[i].msg + '</td>' +
                '<td>' + gameTypeNames[g.games[i].gameType] + '</td>' +
                '<td>' + isRankedNames[g.games[i].isRanked] + '</td>' +
            '</tr>';
    }
    $('#games-list').html(html);
}

var drawLobbyPlayers = function() {
    var html = '';
    var names = [];
    var nameToId = {};
    for (var id in g.lobbyPlayers) {
        names.push(g.lobbyPlayers[id]);
        nameToId[g.lobbyPlayers[id]] = id;
    }
    
    names = names.sort();
    for (var idx = 0; idx < names.length; ++idx) {
        html += '<tr><td>' +
                '<span>' + xmlEscape(names[idx]) +'</span>';
        if (localStorage.mod && JSON.parse(localStorage.mod)) {
            html +=
                '<span class="dropdown pull-right">' +
                  '<button class="btn btn-standard btn-mini dropdown-toggle" type="button" id="banMenu" data-toggle="dropdown" aria-haspopup="true" aria-expanded="true">' +
                    '<span class="caret"></span>' +
                  '</button>' +
                  '<ul class="dropdown-menu" aria-labelledby="dropdownMenu1">' +
                    '<li class="text-center"><b>User Ban</b></li>' +
                    '<li onclick="ban('+nameToId[names[idx]]+', 60*60, 1)"><a href="#">1 hour</a></li>' +
                    '<li onclick="ban('+nameToId[names[idx]]+', 60*60*24, 1)"><a href="#">1 day</a></li>' +
                    '<li onclick="ban('+nameToId[names[idx]]+', 60*60*24*7, 1)"><a href="#">1 week</a></li>' +
                    '<li onclick="ban('+nameToId[names[idx]]+', 60*60*24*7*52, 1)"><a href="#">1 year</a></li>' +
                    '<li class="text-center"><b>IP Ban</b></li>' +
                    '<li onclick="ban('+nameToId[names[idx]]+', 60*60, 2)"><a href="#">1 hour</a></li>' +
                    '<li onclick="ban('+nameToId[names[idx]]+', 60*60*24, 2)"><a href="#">1 day</a></li>' +
                    '<li onclick="ban('+nameToId[names[idx]]+', 60*60*24*7, 2)"><a href="#">1 week</a></li>' +
                    '<li onclick="ban('+nameToId[names[idx]]+', 60*60*24*7*52, 2)"><a href="#">1 year</a></li>' +
                  '</ul>' +
                '</span>'
        }
        html += '</td></tr>';
    }
    
    $('.player-list').html(html);
}

var drawGuns = function() {
    var html = '';
    var width = $('#game-field').width();
    for (var i = 0; i < g.guns.length; ++i) {
        html += '<img id=gun' + i + ' src="gun.png" style="position:absolute; top:' + 200 + 'px; left:' + (width / 2 - 50) + 'px">';
    }
    
    $('#guns-field').html(html);
    
    for (var i = 0; i < g.guns.length; ++i) {
        $('#gun' + i).click(onClickUserTile(g.guns[i]));
    }
}

var drawInvestigator = function() {
  var html = '';
  var width = $('#game-field').width();
  if (g.investigator !== null) {
      html += '<img id=investigator-mark src="investigator.png" style="position:absolute; top:' + 200 + 'px; left:' + (width / 2 - 50) + 'px"></div>';
  }

  $('#investigator-field').html(html);
  $('#investigator-mark').click(onClickUserTile(g.investigator));
}

var drawExcalibur = function() {
  var html = '';
  var width = $('#game-field').width();
  if (g.excalibur !== null) {
      html += '<img id=excalibur-mark src="sword.png" style="position:absolute; top:' + 200 + 'px; left:' + (width / 2 - 50) + 'px"></div>';
  }

  $('#excalibur-field').html(html);
  $('#excalibur-mark').click(onClickUserTile(g.excalibur));
}

var drawGameLog = function() {
    if (g.gamelogIdx < g.gamelogs.length) {
        $('.gamelog-page').html(g.gamelogs[g.gamelogIdx].page);
        $('.gamelog-text').html(g.gamelogs[g.gamelogIdx].text);
    } else {
        $('.gamelog-page').html('');
        $('.gamelog-text').html('');
    }
}

var drawMsgArea = function() {
    if (g.msgs.length > 0) {
        $('#msg-text').html(xmlEscape(g.msgs[0]));
        $('#msg-buttons').html(
            "<button class='btn btn-primary' onclick='onDismissMsg()'>OK</button>");
    } else if (g.choices.length > 0) {
        var choice = g.choices[g.choiceIdx]; 
        var html = '';
        
        if (choice.cmd === 'choosePlayers') {
            var enabled = getHighlights().length === choice.n ? '' : ' disabled';
            html = "<button class='btn btn-success" + enabled + "' onclick='onDismissChoose(getHighlights())'>OK</button> ";
            if (choice.canCancel) {
                html += "<button class='btn btn-danger' onclick='onDismissChoose([])'>Cancel</a> ";
            }
        } else if (choice.cmd === 'choose') {
            html = generateButton('btn-success', choice.choices[0]);
            if (choice.choices.length > 1) {
                html += generateButton('btn-danger', choice.choices[1]);
            }
            if (choice.choices.length > 2) {
                html = generateButton('', choice.choices[2]) + html;
            }
        }
        
        if (g.choices.length > 1) {
            html += "<button class='btn' onclick='onNextChoice()'><i class='icon-chevron-right'></i></button>";
        }
        
        $('#msg-text').html(xmlEscape(choice.msg));
        $('#msg-buttons').html(html);
    }
    else
    {
        $('#msg-text').html(xmlEscape(g.status));
        $('#msg-buttons').html("<button class='btn invisible'>.</button>");
    }
}

var drawClaimButton = function() {
    if (myId && g.highlights3[myId]) {
        $("#claim").addClass("hidden");
        $("#unclaim").removeClass("hidden");
    }
    else if (myId) {
        $("#unclaim").addClass("hidden");
        $("#claim").removeClass("hidden");
    }
}

var drawSettings = function() {
    // Set settings
    $('#anon-mode').prop('checked', g.settings.anonMode);
    $('.anon-category').val(g.settings.anonCategory);
    // Disable or enable ability to set settings (leader and game hasen't started)
    if (g.leader === myId && !g.gamelogs[0]) {
        $('.setting').removeAttr('disabled');
        $('.setting-dropdown').removeAttr('disabled');
    }
    else {
        $('.setting').attr('disabled', 'disabled');
        $('.setting-dropdown').attr('disabled', 'disabled');
    }
    // Show or hide subsettings
    if (g.settings.anonMode) {
        $('.anon-category').removeClass('hidden');
    }
    else {
        $('.anon-category').addClass('hidden');
    }
}

var generateButton = function(btnClass, choice) {
    if (typeof(choice) === 'string') {
        return "<button class='btn " + btnClass + "' onclick='onDismissChoose(\"" + choice + "\")'>" + choice + "</button> ";
    } else {
        return "<div class='btn-group'>" +
            "<a class='btn btn-standard dropdown-toggle' data-toggle='dropdown' href='#'>" + choice[0] + " <span class='caret'></span></a>" +
            "<ul class='dropdown-menu'>" +
            choice.slice(1).map(function (i) { 
                return  "<li><a onclick='onDismissChoose(\"" + i + "\")'>" + i + "</a></li>";
            }).join('') +
            "</ul></div> ";
    }
}

var drawVoteLog = function() {
    var html = '<table><tr><td>&nbsp;</td>';
    for (var i = 0; i < g.votelog.rounds.length; ++i) {
        if (g.votelog.rounds[i] !== 0) {
            html += '<td style="width: 11em" colspan=' + g.votelog.rounds[i] + '>Mission ' + (i + 1) + '</td>';
        }
    }
    html + '</tr>';
    
    for (var i = 0; i < g.players.length; ++i) {
        var id = g.players[i].id;
        html += '<tr><td>' + g.players[i].name + '</td>';
        for (var j = 0; j < g.votelog.leader.length; ++j) {
            var leader = (g.votelog.leader[j] === id) ? 'leader' : '';
            var approve = (g.votelog.approve[j].indexOf(id) >= 0) ? 'approve' : '';
            var reject = (g.votelog.reject[j].indexOf(id) >= 0) ? 'reject' : '';
            var onteam = (g.votelog.onteam[j].indexOf(id) >= 0) ? '<i class="icon-ok"></i>' : '';
            var investigator = (g.votelog.investigator[j] === id) ? '<i class="icon-question-sign"></i>' : '';
            var excalibur = (g.votelog.excalibur[j] === id) ? '<i class="icon-wrench"></i>' : '';
            var excalibured = (g.votelog.excalibured[j] === id) ? '<i class="icon-resize-horizontal"></i>' : '';
            html += '<td class="' + approve + ' ' + reject + ' ' + leader + '">' + onteam + ' ' + investigator + ' ' + excalibur + ' ' + excalibured + '</td>';
        }
        html += '</tr>';
    }
    html += '</table>';

    $('.votelog').html(html);
}

var drawPlayers = function(data) {
        var round = Math.min(g.scoreboard.round || 1, 5);
        for (var i = 0; i < g.players.length; ++i) {
            if (g.players[i].id === g.leader) {
                var hammer = g.players[(i + 5 - round) % g.players.length].id;
            }
        }

        var html = "";
        var takeMode = 
            g.choices.length > 0 &&
            g.choices[g.choiceIdx].cmd === 'chooseTakeCard';
            
        for (var i = 0; i < g.players.length; ++i) {
            var name = g.players[i].name;
            var id = g.players[i].id;
            var isOpinionMaker = g.cards.filter(function(c) { return c.player === id && c.card === 'OpinionMaker' }).length > 0;
            var cards = g.cards
                .filter(function (c) { return c.player === id; })
                .map(function (c) { 
                    var showButton = takeMode && g.choices[g.choiceIdx].players.indexOf(id) !== -1;
                    return "<div class=media>" +
                            (showButton ? "<button class='pull-left btn btn-success btn-mini' onclick='onDismissChoose({ player:" + id + ", card:\"" + c.card + "\" })'>Take</button>" : "") +
                            "<div class=media-body>" + cardNames[c.card] + "</div>" +
                        "</div>"; 
                });
            
            var cardsPopover = "<div class=normal-word-break style='width:200px'>" + cards.join('') + "</div>";
            var cardsTooltip = "<div class=normal-word-break>" + name + " has plot cards. Click for details.</div>";
            var cardsIcon = 
                "<span class=plot-cards data-html=true title=\"" + xmlEscape(cardsTooltip) + "\">" +
                    "<span data-html=true title='<b>Plot cards</b>'  data-content=\"" + xmlEscape(cardsPopover) + "\">" +
                        "<i class='icon-book icon-dark-white'></i>" +
                    "</span>" +
                "</span>";
            
            var opinionMakerTooltip = "<div class=normal-word-break>" + name + " is an Opinion Maker.</div>";
            var opinionMakerIcon = "<span class=opinion-maker><i class=icon-share data-html=true title=\"" + xmlEscape(opinionMakerTooltip) + "\"></i></span>";
            
            var hammerTooltip = "<div class=normal-word-break>" + name + " is the hammer.</div>";
            var hammerIcon = "<span class=hammer><i class='icon-star-empty icon-dark-white' data-html=true title=\"" + xmlEscape(hammerTooltip) + "\"></i></span>";
            
            var labelColor = "";
            var role = g.players[i].role || "";
            var role2 = g.players[i].role2 || "";
            var tooltipText = role;
            if (role2 !== "") {
                tooltipText = role2 + " " + role;
            }
            var labelText = tooltipText;
            if (role === "Resistance" || role === "Spy") {
                labelText = role2;
            }
            if (g.votes[id] != null) {
                labelText = g.votes[id];
                labelColor = (g.votes[id] === 'Approve' ? 'label-success' : 'label-important');
            }

            var avatarImage = g.players[i].isSpy ? g.players[i].spyImg : g.players[i].resImg;
            if (localStorage.originalAvatars && JSON.parse(localStorage.originalAvatars)) {
                avatarImage = g.players[i].isSpy ? 'spy.png' : 'resistance.png';
            }

            var highlight = g.highlights[id];
            var highlight3 = (g.highlights3[id] && !g.highlights[id]);
            var highlight2 = (localStorage.highlight && JSON.parse(localStorage.highlight) && g.highlights2[id] && !highlight);
            var highlight4 = highlight3 && highlight2;
            if (highlight4) { highlight3 = false; highlight2 = false; };
            html += "<div data-toggle='tooltip' title='"+tooltipText+"' id=player" + id + " class='usertile role_tooltip" + (g.highlights[id] ? ' highlight' : '') + (highlight2 ? ' highlight2' : '') + (highlight3 ? ' highlight3' : '') + (highlight4 ? ' highlight4' : '') + "'>" +
                    "<img src='" + avatarImage + "''>" + // image
                    "<br>" + (cards.length !== 0 ? cardsIcon : '') + // cards
                    " <span id='"+id+"-name' class=player_name '"+(highlight3 ? ' claim':'')+"'>" + name + "</span> " + // name
                    (isOpinionMaker ? opinionMakerIcon : '') + (hammer === id ? hammerIcon : '') + // hammer
                    "<br><span class='label " + labelColor + "'>" + labelText + "</span>&nbsp;" + // label
                    "</div>";
        }
        
        if (g.players.length > 0) {
            html += "<img id=leader-star src=leader.png style='position:absolute'>";
        }
        
        $('#game-field').html(html);
        for (var i = 0; i < g.players.length; ++i) {
            $('#player' + g.players[i].id + ' img').click(onClickUserTile(g.players[i].id));
            $('#player' + g.players[i].id + ' .plot-cards').tooltip({placement: 'bottom'});
            $('#player' + g.players[i].id + ' .opinion-maker i').tooltip({placement: 'bottom'});
            $('#player' + g.players[i].id + ' .plot-cards span').popover({placement: 'top'});
            $('#'+g.players[i].id+"-name").click(onClickUserName(g.players[i].id));
        }
        
        $('span.hammer i').tooltip({placement: 'bottom'});
        $('.role_tooltip').tooltip({placement: 'top'});
        
        arrangePlayers();
    }

var arrangePlayers = function(data) {
    if (g.players.length === 0) {
        return;
    }
    
    var itemWidth = $('#player' + g.players[0].id).width();
    var fieldWidth = $('#game-field').parent().width();
    // var fieldHeight = 500;
    var fieldHeight = $('#game-field').parent().height();
    var points = pointsOnAnEllipse(fieldWidth * 0.8, fieldHeight * 0.6, g.players.length);
    for (var i = 0; i < g.players.length; ++i) {
        g.players[i].x = points[i].x + fieldWidth / 2 - itemWidth / 2;
        // g.players[i].y =  points[i].y + 160;
        g.players[i].y = points[i].y + .6 * fieldHeight / 2 + 10;
        $('#player' + g.players[i].id)
            .css('left', g.players[i].x)
            .css('top',  g.players[i].y);
            
        if (g.leader === g.players[i].id) {
            $('#leader-star')
                .css('left', g.players[i].x + leaderOffsetX)
                .css('top',  g.players[i].y + leaderOffsetY)
                .click(onClickUserTile(g.leader));
        }
        
        if (g.investigator === g.players[i].id) {
            $('#investigator-mark')
                .css('left', g.players[i].x + investigatorOffsetX)
                .css('top',  g.players[i].y);
        }

        if (g.excalibur === g.players[i].id) {
            $('#excalibur-mark')
                .css('left', g.players[i].x + excaliburOffsetX)
                .css('top',  g.players[i].y + excaliburOffsetY);
        }
    }
    
    for (var i = 0; i < g.guns.length; ++i) {
        var pos = $('#player' + g.guns[i]).position();
        $('#gun' + i).css('left', pos.left + gunsOffsetX).css('top', pos.top + gunsOffsetY);
    }
}

var pointsOnAnEllipse = function(width, height, n) {
    var m = 1000;
    var x = [];
    var y = [];
    for (var i = 0; i < m; ++i) {
        var angle = i / m * 2 * Math.PI;
        x.push(Math.sin(angle) * width / 2);
        y.push(-Math.cos(angle) * height / 2);
    }
    
    var total = 0;
    var x2 = x[x.length - 1];
    var y2 = y[y.length - 1];
    for (i = 0; i < m; ++i) {
        x1 = x2;
        y1 = y2;
        var x2 = x[i];
        var y2 = y[i];
        total += Math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));
    }
    
    var ans = [];
    var runningTotal = 0;
    var x2 = x[x.length - 1];
    var y2 = y[y.length - 1];
    for (i = 0; i < m; ++i) {
        x1 = x2;
        y1 = y2;
        x2 = x[i];
        y2 = y[i];
 
       runningTotal += Math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));
        if (runningTotal >= 0) {
            ans.push({x: x2, y: y2});
            runningTotal -= total / n;
        }
    }
    
    return ans;
}

var xmlEscape = function(s) {
    return s
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/'/g, '&apos;')
        .replace(/"/g, '&quot;');
}

var urlify = function(text) {
    var urlRegex = /(https?:\/\/[^\s]+)/g;
    return text.replace(urlRegex, function(url) {
        return '<a href="' + url + '" target="_blank">' + url + '</a>';
    })
    // or alternatively
    // return text.replace(urlRegex, '<a href="$1">$1</a>')
}

var getId = function(name) {
    var players = g.players.filter(function(obj) { return obj.name.toLowerCase() === name.toLowerCase(); })
    if (players.length > 0) {
        return players[0].id;
    }
    return null;
}

var isMuted = function(name) {
    for (var i = 0; i < mutedPlayers.length; i++) {
        if (mutedPlayers[i].toLowerCase() === name.toLowerCase()) {
            return true;
        }
    }
    return false;
}

var inGame = function(id) {
    if (!id) return false;
    for (var i = 0; i < g.players.length; i++) {
        if (g.players[i].id === id) {
            return true;
        }
    }
    return false;
}

var hideAnimationChatBelow = function(element) {
    setTimeout(function() { 
        element.css({ "border-bottom":"none" }); 
    }, 1500);
}

var updateChat = function(selectors, data) {
    var id = getId(data.player);
    var highlight = id && g.textHighlights[id] && localStorage.highlightText && JSON.parse(localStorage.highlightText);
    var msg = data.serverMsg ? urlify(data.msg) : urlify(xmlEscape(data.msg));
    var player = data.serverMsg ? data.player : xmlEscape(data.player);
    // color?
    var color = "";
    if (data.serverMsg) color = "color: teal;";
    if (data.isPrivate) color = "color: gray;";
    if (data.privateMsg) color = "color: blue;";

    selectors.each(function(i, element) {
        selector = $(element);
        var currentDiv = selector.children(".current");
        var lines = (currentDiv.data("lines") || 0) + 1;
        var lineToAppend = "";
        if (data.custom) {
            lineToAppend = msg;
        }
        else {
            lineToAppend = "<code>[" + new Date().toTimeString().substring(0, 5) + "]</code> " +
                            "<span style='" + color + "'" +
                                    "class='" + (id ? id+"-chat" : "") + (highlight ? " chat-highlight" : "") + "'>" +
                            "<b>" + player + "</b>: " + 
                            msg + "</span>" + (data.noBreak ? "" : "<br>")
        }
        currentDiv.append(lineToAppend);
        currentDiv.data("lines", lines);
        if (lines >= 10) {
            var innerHtml = currentDiv.html();
            currentDiv.remove();
            selector.append("<div>" + innerHtml + "</div><div class='current'></div>");
        }

        var shouldScroll = false;
        if (selector.prop("scrollTop") + selector.height() + 50 >= selector.prop('scrollHeight'))
        {
            shouldScroll = true;
        }
        if(shouldScroll){
            selector.prop({scrollTop: selector.prop('scrollHeight')});
        }else{
            selector.css({"border-bottom":"3px dashed red"});
            hideAnimationChatBelow(selector);
        }
    });
}

var getHighlights = function() {
    return Object.keys(g.highlights)
        .filter(function(i) { return g.highlights[i]; })
        .map(function(i) { return parseInt(i, 10); });
}

var sendAjax = function(x, verb, poll) {
    //debugLog.push({ dir:'OUT', verb:verb, body:x });

    return $.ajax(
        '/server/play', { 
        cache: false,
        type: verb || 'POST', 
        processData: false,
        contentType: 'application/json',
        data: x == null ? '' : JSON.stringify(x) })
    .fail(function(xmlHttpRequest, code, error)
    {
        if (xmlHttpRequest.status === 401) {
            window.alert('There was a network error. Please log back in.\n\n' + code + '\n' + error + '\n' + xmlHttpRequest.responseText);
            window.location = '/';  
        }
        else {
            if (code === "timeout" && poll) {
                return pollLoop();
            }
            // onChat({player:"", serverMsg:false, msg:"You have disconnected. You may be missing some chat."});
            setTimeout(function() {sendAjax({cmd:'reconnect'}); if (poll) {pollLoop();}}, 2000);
        }    
    });
}

var sendData = function(data) {
    if (socket) {
        socket.emit('play', data);
    }
    else {
        sendAjax(data);
    }
}

var sendAjaxTo = function(x, verb, location) {
    return $.ajax(
        location, { 
        type: verb || 'POST', 
        processData: false,
        contentType: 'application/json',
        data: x == null ? '' : JSON.stringify(x) })
    .fail(function(xmlHttpRequest, code, error)
    {
        window.alert('There was a network error. Please log back in.\n\n' + code + '\n' + error + '\n' + xmlHttpRequest.responseText);
        window.location = '/';        
    });
}
var ban = function(playerId, duration, banType) {
    sendAjaxTo({ playerId:playerId, duration:duration, banType:banType }, 'POST', '/server/ban')
        .done(function(data) {
        })
}

var pollLoop = function() {
    var num = pollNum;
    sendAjax(null, "GET", true)
        .done(function(data) {
            //debugLog.push({ dir:'IN', verb:'GET' });
            for (var i = 0; i < data.length; ++i) {
                //debugLog.push({ dir:'IN', verb:'GET', body: data[i] });
                var handler = handlers[data[i].cmd];
                if (handler != null) {
                    try {
                        handler(data[i]);
                    } catch (e) {
                        sendAjax({ cmd: 'clientCrash', exception:e, msg:data[i] });
                        setTimeout(function() {sendAjax({cmd:'reconnect'});}, 2000);
                    }
                }
            }
            if (pollNum === num) {
                pollLoop();
            }
        });
}

var highlightTab = function(selector) {
    if (!$(selector).hasClass('active')) {
        $(selector + ' a').addClass('tab-highlight');
    }
}

var unhighlightTab = function(selector) {
    return function() {
        $(selector + ' a').removeClass('tab-highlight');
    }
}

var scrollToBottom = function(selectors) {
    return function() {
        $(selectors).each(function(i, selector) {
            $(selector).prop({scrollTop: $(selector).prop('scrollHeight')});
        });
    }
}

var resizeElements = function(fieldHeight) {
    // TODO:
    $('#scoreboard').css('top', .6 * fieldHeight / 2 + 25);
    var windowScroll = $(window).scrollTop() + $(window).height();
    var gameBottom = $('#game-container').height() + $('#game-container').position().top + 20;
    $('.resizable').each(function(index, element) {
        var newHeight = $(this).height() + (windowScroll - gameBottom);
        if (newHeight > parseInt($(this).attr('data-min-height'))) {
            $(this).height(newHeight);
        }
        else {
            $(this).height(parseInt($(this).attr('data-min-height')));
        }
    });
}

// On page load ...
$(function() {
    var game_field_width = $('#game-field').width();
    var game_field_height = $('#game-field').parent().height();
    setInterval(function() {
        var w = $('#game-field').width();
        var h = $('#game-field').parent().height();
        if (w !== game_field_width || h !== game_field_height) {
            arrangePlayers();
            resizeElements(h);
        }
        game_field_width = w;
        game_field_height = h;
    }, 100);
    $('#settings-dialog').dialog({ autoOpen: false, modal: true });
    $(document).on('click', '.ui-widget-overlay', function () {
        $('.dialog').dialog('close');
    });
    
    $('.all-chat-nav-tab')
        .click(unhighlightTab('.all-chat-nav-tab'))
        .on('shown', scrollToBottom('.all-chat-text'));
    $('.chat-nav-tab')
        .click(unhighlightTab('.chat-nav-tab'))
        .on('shown', scrollToBottom('.chat-text'));
    $('#new-game-original').click(onCreateGame(1,false));
    $('#new-game-avalon').click(onCreateGame(2,false));
    $('#new-game-basic').click(onCreateGame(3,false));
    $('#new-game-hunter').click(onCreateGame(5,false));
    $('#new-game-trump').click(onCreateGame(2,false,2));
    $('#new-game-original-r').click(onCreateGame(1,true));
    $('#new-game-avalon-r').click(onCreateGame(2,true));
    $('#new-game-basic-r').click(onCreateGame(3,true));
    $('#new-game-hunter-r').click(onCreateGame(5,true));
    $('#leave-game').click(onLeaveGame);
    $('.prev-gamelog').click(onPrevGameLog);
    $('.next-gamelog').click(onNextGameLog);
    $('.chat-input').keypress(onEnter('chat'));
    $('#lobby-chat-input').keypress(onEnter('allChat'));
    $('.all-chat-input').keypress(onEnter('allChat'));
    $('#claim').click(onClickClaim(true));
    $('#unclaim').click(onClickClaim(false));
    $('.poll-button').click(onClickPoll());
    $('.role-choice').click(onClickRoleChoice(false));
    $('.cancel-choose-role').click(onClickRoleChoice(true));
    $('.settings').click(onClickSettings);
    $('.setting').on('click', onClickSetting());
    $('.setting-dropdown').on('change', onChangeSetting());

    $('.autocomplete-input').keydown(function(event) {
        if (event.keyCode !== 9) return true; // Not tab?
        autocomplete($(this), objectToArray(g.lobbyPlayers));
        return false;
    });
    $('#field-container').resizable({ handles: "s", maxHeight: 500, minHeight: 370 });
    
    pollLoop();
    sendData({cmd:'refresh'});

    initOptionsJS();
    initDiscussions();
    initNotifications();

});
