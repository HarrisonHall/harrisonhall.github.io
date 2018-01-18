var previousActiveContainer;
var previousScroll = 0;
var rootId;
var discussionId;
var posts = [];
var postViews = [];

// Discussion page

////////////////////////////////////////////////////////////
// HTML FUNCTIONS
////////////////////////////////////////////////////////////

if (!Array.prototype.find) {
  Array.prototype.find = function(predicate) {
    if (this === null) {
      throw new TypeError('Array.prototype.find called on null or undefined');
    }
    if (typeof predicate !== 'function') {
      throw new TypeError('predicate must be a function');
    }
    var list = Object(this);
    var length = list.length >>> 0;
    var thisArg = arguments[1];
    var value;

    for (var i = 0; i < length; i++) {
      value = list[i];
      if (predicate.call(thisArg, value, i, list)) {
        return value;
      }
    }
    return undefined;
  };
}

var isFirstLevel = function(postId) {
    var post = posts.find(function(obj) { return obj.id === postId; });
    return post.parent_id === rootId;
};

var makeEditForm = function(isReply, id, content) {
    var reply = isReply ? '' : '';
    var html =  '<div class=" edit-form ' + reply + ' hidden" data-id=' + id + '>' +
                    '<textarea class="post-reply-text" type="text" placeholder="Edited text..." rows="1">' + content + '</textarea>' +
                    '<div class="button-group">' +
                        '<button class="save-edit-post btn btn-small">Save</button>' +
                        '<button class="cancel-edit-post btn btn-small">Cancel</button>' +
                    '</div>' +
                '</div>';
    return html;
};

var makePostInput = function(isReply, isHidden, id) {
    var reply = isReply ? 'reply' : 'first-level';
    var hidden = isHidden ? 'hidden' : '';
    var replyOrComment = isReply ? 'reply' : 'comment';
    var html =  '<div class=" post-input ' + reply + ' ' + hidden + '" data-id=' + id + '>' +
                    '<textarea class="post-reply-text" type="text" placeholder="Your ' + replyOrComment + '..." rows="1"></textarea>' +
                    '<div class="button-group">' +
                        '<button class="save-post btn btn-small">Save</button>' +
                        (isReply ? '<button class="cancel-post btn btn-small">Cancel</button>' : '') +
                    '</div>' +
                '</div>';
    return html;
};

var makePost = function(post, isReply) {
    var reply = isReply ? 'reply' : 'first-level';
    var content = post.no_escape ? post.content : urlify(escapeText(post.content));
    var html =  '<div class="post post-' + post.id + ' ' + reply + '" data-id=' + post.id + ' data-poster_id=' + post.poster_id + '>' +
                    '<p class="tagline">' +
                        '<span class="post-name">' + post.name + '</span>' +
                        '<span class="num-likes">' + post.num_likes + ' like' + addS(parseInt(post.num_likes, 10)) + ' </span>' +
                        '<time class="create-time" datetime="' + post.create_time + '" title="' + (new Date(post.create_time)).toString() + '">' +
                            timeSince(post.create_time, post.current_time) +
                        '</time>' +
                        '<time datetime="' + post.update_time + '" ' +
                            'title="last edited ' + timeSince(post.update_time, post.current_time) + '">' +
                            (post.is_edited ? '&#42;' : '') +
                        '</time>' +
                        (isReply && !isFirstLevel(post.parent_id) ? '<span class="replied-to"> → ' + post.replied_name + '</span>' : '') +
                    '</p>' +
                    '<div class="post-content">' +
                        '<p class="post-content-text" data-text="' + escapeText(post.content) + '">' + content + '</p>' +
                        makeEditForm(isReply, post.id, post.content) +
                    '</div>' +
                    '<p class="post-buttons">' +
                        '<span class="post-comment">Reply</span>' +
                        '<span class="post-like">Like</span>' +
                        '<span class="post-unlike hidden">Unlike</span>' +
                        '<span class="post-edit hidden">Edit</span>' +
                        '<span class="post-delete hidden">Delete</span>' +
                        '<span class="post-delete-confirm hidden">Confirm Delete</span>' +
                        '<span class="post-delete-cancel hidden">Cancel</span>' +
                    '</p>' +
                '</div>';
    return html;
};

var makePostGroup = function(post) {
    var html = '<div class="post-group">' +
                    '<div class="post-chain">' +
                        makePost(post, false) +
                        '<div class="post-replies">' +
                        '</div>' +
                    '</div>' +
                    makePostInput(true, true, post.id) +
                '</div>';
    return html;
};

var makeRootPost = function(post) {
    var content = post.no_escape ? post.content : urlify(escapeText(post.content));
    var html = '<div class="post root-post post-' + post.id + ' first-level" data-id=' + post.id + ' data-poster_id=' + post.poster_id + '>' +
                    '<h3>' + escapeText(post.title) + '</h3>' +
                    '<p class="tagline">' +
                        '<span class="post-name">' + post.name + '</span>' +
                        '<span class="num-likes">' + post.num_likes + ' like' + addS(parseInt(post.num_likes, 10)) + ' </span>' +
                        '<time class="create-time" datetime="' + post.create_time + '" title="' + (new Date(post.create_time)).toString() + '">' +
                            timeSince(post.create_time, post.current_time) +
                        '</time>' +
                        '<time datetime="' + post.update_time + '" ' +
                            'title="last edited ' + timeSince(post.update_time, post.current_time) + '">' +
                            (post.is_edited ? '&#42;' : '') +
                        '</time>' +
                    '</p>' +
                    '<div class="post-content">' +
                        '<p class="post-content-text" data-text="' + escapeText(post.content) + '">' + content + '</p>' +
                        makeEditForm(false, post.id, post.content) +
                    '</div>' +
                    '<p class="post-buttons">' +
                        '<span class="post-comment">Comment</span>' +
                        '<span class="post-like">Like</span>' +
                        '<span class="post-unlike hidden">Unlike</span>' +
                        '<span class="post-edit hidden">Edit</span>' +
                        '<span class="post-delete hidden">Delete</span>' +
                        '<span class="post-delete-confirm hidden">Confirm Delete</span>' +
                        '<span class="post-delete-cancel hidden">Cancel</span>' +
                    '</p>' +
                '</div>';
    return html;
};

var setPost = function(post) {
    if (post.parent_id === rootId) {
        $('.post-groups').append(makePostGroup(post));
    }
    else {
        if (isFirstLevel(post.parent_id)) {
            $('.post-'+post.parent_id).parent().find('.post-replies').append(makePost(post, true));
        }
        else {
            $('.post-'+post.parent_id).closest('.post-replies').append(makePost(post, true));
        }
    }
};

var setMainDiscussionContent = function(posts) {

    rootId = posts[0].id;
    discussionId = posts[0].id;
    var html =  '<div class="post-group">' + makeRootPost(posts[0]) + '<hr>' + '<div class="post-groups"></div>' + makePostInput(false, false, rootId) + '</div>';
    $('.main-discussion-content').html(html);
    for (var i = 1; i < posts.length; i++) {
        setPost(posts[i]);
    }

};

// Discussions table

var makeDiscussionRow = function(discussion) {
    var html = '<tr class="discussion-item discussion-item-' + discussion.id + '" data-update-time="' + discussion.post_update + '" data-id="' + discussion.id + '">' +
                '<td class="discussion-row-data">' + escapeText(discussion.title) + '</td>' +
                '<td class="discussion-row-data">' + discussion.name + '</td>' +
                '<td>' + timeSince(discussion.post_update, discussion.current_time) + '</td>' +
                '</tr>';
    return html;

};
var makeDiscussionRows = function(discussions) {
    var rows = '';
    for (var i = 0; i < discussions.length; i++) {
        rows += makeDiscussionRow(discussions[i]);
    }
    return rows;
};

var makeDiscussionRowFull = function(discussion) {
    //  <thead><tr><th>Title</th><th>By</th><th>Date</th><th>Posts</th><th>Last By</th><th>Updated</th></tr></thead>
    var html = '<tr class="discussion-item discussion-item-' + discussion.id + '" data-update-time="' + discussion.post_update + '" data-id="' + discussion.id + '">' +
                '<td>' + discussion.title + '</td>' +
                '<td>' + discussion.name + '</td>' +
                '<td>' + timeSince(discussion.post_date, discussion.current_time) + '</td>' +
                '<td>' + discussion.num_posts + '</td>' +
                '<td>' + discussion.last_name + '</td>' +
                '<td>' + timeSince(discussion.post_update, discussion.current_time) + '</td>' +
                '</tr>';
    return html;
};
var makeDiscussionRowsFull = function(discussions) {
    var rows = '';
    for (var i = 0; i < discussions.length; i++) {
        rows += makeDiscussionRowFull(discussions[i]);
    }
    return rows;
};


////////////////////////////////////////////////////////////
// CLIENT-SERVER FUNCTIONS
////////////////////////////////////////////////////////////

var getDiscussion = function(id, shouldScroll, cb) {
    sendAjaxTo({}, 'GET', 'server/discussions/'+id)
        .done(function(data) {
            posts = data.discussion;
            setMainDiscussionContent(posts);
            changeContentContainer('#discussion-container', shouldScroll); // go to discussion container
            postGetId(function() {
                getLikes(discussionId);
                setDiscussionViews(id);
                getViews();
                setEdit();
            });
            // set handlers
            setHandlers();
            if (cb) cb();
        });
};

var postGetId = function(cb) {
    sendAjaxTo({}, 'GET', 'server/role') // get my id first
        .done(function(data) {
            myId = data.id;
            cb();
        });
};

var getViews = function() {
    sendAjaxTo({}, 'GET', 'server/views')
        .done(function(data) {
            postViews = data.views;
            setDiscussionRowViews();
        });
};

var getLikes = function(id) {
    sendAjaxTo({}, 'GET', 'server/likes/'+id)
        .done(function(data) {
            var likes = data.likes;
            for (var i = 0; i < likes.length; i++) {
                if (likes[i].player_id === myId) {
                    var $post = $('.post-'+likes[i].post_id);
                    $post.find('.post-like').addClass('hidden');
                    $post.find('.post-unlike').removeClass('hidden');
                }
            }
        });
};


////////////////////////////////////////////////////////////
// DOM FUNCTIONS
////////////////////////////////////////////////////////////

var dismissContentContainer = function() {
    $('.content-container').addClass('hidden');
    previousActiveContainer.removeClass('hidden');
    $('html, body').animate({ scrollTop: previousScroll }, 0, function() { });
};

var changeContentContainer = function(id, shouldScroll) {
    isSameContainer = $('.content-container').not('.hidden').first().attr('id') === id.replace('#','');
    previousActiveContainer =  (isSameContainer ? previousActiveContainer : $('.content-container').not('.hidden'));
    if (!isSameContainer) previousScroll = $(window).scrollTop();
    $('.content-container').addClass('hidden');
    $(id).removeClass('hidden');
    if (shouldScroll) $('html, body').animate({ scrollTop: 0 }, 0, function() { });
};

var setHandlers = function() {
    $('.save-post').click(onSavePost);
    $('.cancel-post').click(onCancelPost());
    $('.post-comment').click(onPostComment);
    $('.post-like').click(onPostLike);
    $('.post-unlike').click(onPostUnlike);
    $('.post-edit').click(onPostEdit);
    $('.post-input.reply > textarea').blur(onCancelPost(2000));
    $('.save-edit-post').click(onSaveEditPost);
    $('.cancel-edit-post').click(onCancelEditPost);
    $('.post-delete').click(onPostDelete);
    $('.post-delete-cancel').click(onPostDeleteCancel);
    $('.post-delete-confirm').click(onPostDeleteConfirm);
};

var setEdit = function() {
    $('.post').each(function() {
        if (parseInt($(this).attr('data-poster_id'), 10) === myId) {
            $(this).find('.post-edit').removeClass('hidden');
            $(this).find('.post-delete').removeClass('hidden');
        }
    });
};

var setDiscussionViews = function(discussionId) {
    var discussionView = postViews.find(function(obj) { return obj.post_id === parseInt(discussionId, 10); });
    $('.post').addClass('post-unseen');
    if (!discussionView) return;
    var discussionViewDate = discussionView.create_time;
    $('.post').each(function() {
        var postDate = $(this).find('.create-time').attr('datetime');
        if (newerDate(discussionViewDate, postDate)) {
            $(this).removeClass('post-unseen');
        }
    });
};

var setDiscussionRowViews = function() {
    $('.discussion-item').addClass('discussion-unviewed');
    for (var i = 0; i < postViews.length; i++) {
        var $item = $('.discussion-item-'+postViews[i].post_id);
        var itemDate = $item.attr('data-update-time');
        if (newerDate(postViews[i].create_time, itemDate)) { // Viewed more recently than last update
            $item.removeClass('discussion-unviewed');
        }
    }
};

var discussionRowEnter = function() {
    $(this).children('td').css('background-color', '#BCDEEA');
};
var discussionRowLeave = function() {
    $(this).children('td').css('background-color', '#D0E8F0');
};

////////////////////////////////////////////////////////////
// EVENT HANDLERS
////////////////////////////////////////////////////////////

var onPostDelete = function() {
    $(this).closest('.post-buttons').find('.post-delete').addClass('hidden');
    $(this).closest('.post-buttons').find('.post-delete-confirm').removeClass('hidden');
    $(this).closest('.post-buttons').find('.post-delete-cancel').removeClass('hidden');
};

var onPostDeleteCancel = function() {
    $(this).closest('.post-buttons').find('.post-delete').removeClass('hidden');
    $(this).closest('.post-buttons').find('.post-delete-confirm').addClass('hidden');
    $(this).closest('.post-buttons').find('.post-delete-cancel').addClass('hidden');
};

var onPostDeleteConfirm = function() {
    var id = parseInt($(this).closest('.post').attr('data-id'), 10);
    sendAjaxTo({ postId: id }, 'DELETE', 'server/posts')
        .done(function(data) {
            getDiscussion(discussionId, false);
        });
};

var onClickDismissContentContainer = function() {
    history.back();
};


var onClickContentContainer = function(id) {
    return function() {
        history.pushState({ type: 'create discussion' }, 'create discussion');
        changeContentContainer(id);
    };
};

var onCreateDiscussion = function() {
    var title = $('#discussion-title').val();
    var content = $('#discussion-content').val();
    sendAjaxTo({ title: title, content: content }, 'POST', 'server/discussions')
        .done(function(data) {
            onGetDiscussions();
        });
    $('#discussion-title').val('');
    $('#discussion-content').val('');
};

var onGetDiscussion = function() {
    var id = $(this).attr('data-id');
    // window.location = '#/discussions/'+id;
    getDiscussion(id, true);
    history.pushState({ type: 'discussion', id: id  }, 'discussion');
};

var onGetDiscussions = function() {
    sendAjaxTo({}, 'GET', 'server/discussions')
        .done(function(data) {
            $('.discussions-list tbody').html(makeDiscussionRows(data.discussions));
            $('.discussions-list-full tbody').html(makeDiscussionRowsFull(data.discussions));
            $('.discussion-item').click(onGetDiscussion);
            getViews();
        });
};

var onSavePost = function() {
    var $textarea = $(this).closest('.post-input').find('textarea').first();
    var content = $textarea.val();
    var parentId = $(this).closest('.post-input').attr('data-id');
    $textarea.val('');
    sendAjaxTo({ discussionId: discussionId, parentId: parentId, content: content }, 'POST', 'server/posts')
        .done(function(data) {
            getDiscussion(discussionId, false);
        });
};

var onCancelPost = function(timeout) {
    return function() {
        var $postInput = $(this).closest('.post-input');
        $postInput.find('textarea').focusout();
        var time = timeout || 0;
        setTimeout(function() { $postInput.addClass('hidden'); }, time);
    };
};

var onSaveEditPost = function() {
    var postId = parseInt($(this).closest('.post').attr('data-id'), 10);
    var $editForm = $(this).closest('.edit-form');
    var content = $editForm.find('textarea').val();
    var title = (postId === rootId ? $('.root-post').find('h3').first().html() : '');
    var $postContentText = $(this).closest('.post').find('.post-content-text');
    $postContentText.html(urlify(escapeText(content)));
    $postContentText.attr('data-text', escapeText(content));
    $editForm.addClass('hidden');
    $postContentText.removeClass('hidden');
    sendAjaxTo({ postId: postId, title: title, content: content }, 'PUT', 'server/posts')
        .done(function(data) {
        });
};

var onCancelEditPost = function() {
    var $editForm = $(this).closest('.edit-form');
    var $postContentText = $(this).closest('.post').find('.post-content-text');
    var content = replaceText($postContentText.attr('data-text'));
    console.log($postContentText.attr('data-text'));
    console.log(replaceText($postContentText.attr('data-text')));
    $editForm.find('textarea').val(content);
    $editForm.addClass('hidden');
    $postContentText.removeClass('hidden');
};

var onPostEdit = function() {
    $(this).closest('.post').find('.edit-form').removeClass('hidden');
    $(this).closest('.post').find('.post-content-text').addClass('hidden');
};

var onPostComment = function() {
    var id = $(this).closest('.post').attr('data-id');
    var $postInput = $(this).closest('.post-group').find('.post-input').last();
    $postInput.attr('data-id', id);
    $postInput.removeClass('hidden');
    $postInput.scrollView($postInput.find('textarea'));
};

var onPostLike = function() {
    var id = $(this).closest('.post').attr('data-id');
    sendAjaxTo({ postId: id }, 'POST', 'server/likes')
        .done(function(data) {
            $post = $('.post-'+id);
            $post.find('.post-like').addClass('hidden');
            $post.find('.post-unlike').removeClass('hidden');
            numLikes = parseInt($post.find('.num-likes').html(), 10) + 1;
            $post.find('.num-likes').html(numLikes + ' like' + addS(numLikes) + ' ');
        });
};

var onPostUnlike = function() {
    var id = $(this).closest('.post').attr('data-id');
    sendAjaxTo({ postId: id }, 'DELETE', 'server/likes')
        .done(function(data) {
            $post = $('.post-'+id);
            $post.find('.post-like').removeClass('hidden');
            $post.find('.post-unlike').addClass('hidden');
            numLikes = parseInt($post.find('.num-likes').html(), 10) - 1;
            $post.find('.num-likes').html(numLikes + ' like' + addS(numLikes) + ' ');
        });
};

////////////////////////////////////////////////////////////
// INIT
////////////////////////////////////////////////////////////

function initDiscussions() {
    previousActiveContainer = $('.content-container').not('.hidden');

    $('.new-discussion').click(onClickContentContainer('#new-discussion-container'));
    $('.refresh-discussions').click(onGetDiscussions);

    $('.dismiss-content-container').click(onClickDismissContentContainer);

    $('#create-discussion').click(onCreateDiscussion);

    window.onpopstate = function(event) {
        if (!event.state) {
            // history.back();
            console.log('no state');
        }
        else if (event.state.type === 'default') {
            dismissContentContainer();
        }
        else if (event.state.type === 'create discussion') {
            changeContentContainer('#new-discussion-container');
        }
        else {
            getDiscussion(event.state.id);
        }
    };

    onGetDiscussions();
    history.replaceState({ type: 'default' }, 'default');
}
