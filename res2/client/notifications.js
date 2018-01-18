var notifications = [];

var makeNotification = function(notification) {
    var unseen = notification.is_seen ? '' : 'unseen';
    if (notification.type === 1) {
        html = '<li><a href="#" tabIndex="-1" style="white-space:normal;" class="notification post-notification ' + unseen + '" data-notification-id="' + notification.id + '" data-post-id="' + notification.post_id + '" data-discussion-id="' + notification.discussion_id + '">' +
                    '<span class="notif-message"><span class="notif-name">' + notification.name + '</span> <span class="notif-verb">replied</span> to your post.' + '</span>' +
                    '<br>' +
                    '<time class="notif-time tagline">' + timeSince(notification.create_time, notification.current_time) + '</time>' +
                    '<span class="notif-hide pull-right">Hide</span>' +
                '</a></li>';
    }
    else if (notification.type === 2) {
        html = '<li><a href="#" tabIndex="-1" style="white-space:normal;" class="notification post-notification ' + unseen + '" data-notification-id="' + notification.id + '" data-post-id="' + notification.post_id + '" data-discussion-id="' + notification.discussion_id + '">' +
                    '<span class="notif-message"><span class="notif-name">' + notification.name + '</span> <span class="notif-verb">liked</span> your post.' + '</span>' +
                    '<br>' +
                    '<time class="notif-time tagline">' + timeSince(notification.create_time, notification.current_time) + '</time>' +
                    '<span class="notif-hide pull-right">Hide</span>' +
                '</a></li>';
    }
    else {
        html = '<li><a href="#" tabIndex="-1" style="white-space:normal;" class="notification message-notification ' + unseen + '" data-notification-id="' + notification.id + '">' +
                    '<div style="width:100%; word-wrap:break-word;"><span class="notif-message"><span class="notif-content">' + notification.content + '</span></span></div>' +
                    '<time class="notif-time tagline">' + timeSince(notification.create_time, notification.current_time) + '</time>' +
                    '<span class="notif-hide pull-right">Hide</span>' +
                '</a></li>';
    }
    return html;
};

var setNotifications = function(notifications) {
    var html = '';
    for (var i = 0; i < notifications.length; i++) {
        html += makeNotification(notifications[i]);
    }
    if (notifications.length === 0) {
        html = '<li><span style="margin-left: 5px;">No notifications :(</span></li>';
    }
    $('#notificationsDropdown').html(html);
    var numNotifs = notifications.filter(function(obj) {
        return obj.is_seen === false;
    }).length;
    var notifTitle = 'Notifications' + (numNotifs > 0 ? ' (' + numNotifs + ')' : '');
    $('.notif-title').html(notifTitle);
};

var setNotificationsTitle = function() {
    var numNotifs = $('.notification.unseen').parent().not('.hidden').length;
    var notifTitle = 'Notifications' + (numNotifs > 0 ? ' (' + numNotifs + ')' : '');
    $('.notif-title').html(notifTitle);
};

var setNotificationsHandlers = function() {
    $('.post-notification').on('click', onClickPostNotification);
    $('.notif-hide').on('click', onClickHideNotification);
    $('.message-notification').on('click', onClickMessageNotification);
};

var getNotifications = function() {
    sendAjaxTo({}, 'GET', 'server/notifications')
        .done(function(data) {
            notifications = data.notifications;
            setNotifications(data.notifications);
            // set handlers
            setNotificationsHandlers();
        });
};

var updateNotification = function(notificationId) {
    sendAjaxTo({ notificationId: notificationId }, 'PUT', 'server/notifications')
        .done(function(data) {
        });
};

var hideNotification = function(notificationId) {
      sendAjaxTo({ notificationId: notificationId }, 'DELETE', 'server/notifications')
        .done(function(data) {
        });
};

onClickHideNotification = function(event) {
    var $notification = $(this).closest('.notification');
    var notificationId = $notification.attr('data-notification-id');
    hideNotification(notificationId);
    $notification.parent().addClass('hidden');
    setNotificationsTitle();
    return false;
};

var onClickPostNotification = function(event) {
    var $target = $( event.currentTarget ),
       notificationId = $target.attr( 'data-notification-id' ),
       postId = $target.attr('data-post-id'),
       discussionId = $target.attr('data-discussion-id');

    getDiscussion(discussionId, false, function() {
        $post = $('.post-'+postId);
        $post.scrollView(false, true);
        $post.addClass('post-featured');
        setTimeout(function() {
            $post.removeClass('post-featured');
        }, 3000);
    });
    $target.removeClass('unseen');
    $( event.target ).blur();
    $target.blur();

    isDiscussionContainer = $('.content-container').not('.hidden').first().attr('id') === 'discussion-container';
    if (!isDiscussionContainer) history.pushState({ type: 'discussion', id: discussionId  }, 'discussion');
    else history.replaceState({ type: 'discussion', id: discussionId  }, 'discussion');
    updateNotification(notificationId);
    setNotificationsTitle();
    return false;
};

onClickMessageNotification = function(event) {
    var $target = $( event.currentTarget );
    var notificationId = $target.attr( 'data-notification-id' );
    $target.removeClass('unseen');
    $( event.target ).blur();
    $target.blur();
    updateNotification(notificationId);
    setNotificationsTitle();
    return false;
};


function initNotifications() {
    getNotifications();
    setInterval(function() {
        getNotifications();
    }, 30000);
}
