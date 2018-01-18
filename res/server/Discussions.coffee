
class Discussions
    # TODO: More descriptive error
    constructor: (@db) ->

    getDiscussions: (cb) ->
        @db.getDiscussions (err, discussions) ->
            return cb(404) if err?
            cb { discussions: discussions }

    getDiscussion: (discussionId, cb) ->
        @db.getDiscussion discussionId, (err, discussion) ->
            cb(400) if err?
            cb { discussion: discussion }

    getLikes: (discussionId, cb) ->
        @db.getLikes discussionId, (err, likes) ->
            cb(400) if err?
            cb { likes: likes }

    getPost: (postId, cb) ->
        @db.getPost postId, (err, post) =>
            return cb(400) if err?
            return cb { post: post }

    getViews: (playerId, cb) ->
        @db.getViews playerId, (err, views) =>
            return cb(400) if err?
            return cb { views: views }


    createPost: (player, data, cb) ->
        return cb(400) if data.content.length > 32768
        @db.createPost data.discussionId, data.parentId, player.id, data.content, (err, result) =>
            return cb(400) if err?
            @db.getParentPost result.id, (err, res) => # Notification
                return cb(400) if err?
                @createNotification player, { playerId: res.poster_id, notifierId: player.id, postId: result.id, type: 1 }, cb


    createDiscussion: (player, data, cb) ->
        return cb(400) if data.content.length > 32768 or data.title.length > 256
        @db.createDiscussion player.id, data.title, data.content, (err, result) ->
            return cb(400) if err?
            return cb(200)

    createLike: (player, data, cb) ->
        @db.createLike player.id, data.postId, (err, result) =>
            return cb(400) if err?
            @db.getPost data.postId, (err, post) => # notification
                return cb(400) if err?
                @createNotification player, { playerId: post.poster_id, notifierId: player.id, postId: data.postId, type: 2 }, cb

    createView: (player, postId, cb) ->
        @db.createView player.id, postId, (err, result) ->
            return cb(400) if err?
            return cb(200)


    updatePost: (player, data, cb) ->
        return cb(400) if data.content.length > 32768 or data.title.length > 256
        @db.getPost data.postId, (err, post) =>
            return cb(400) if err?
            return cb(403) if player.id isnt post.poster_id
            @db.updatePost data.postId, data.title, data.content, (err, result) ->
                return cb(400) if err?
                return cb(200)

    deletePost: (player, data, cb) ->
        @db.getPost data.postId, (err, post) =>
            return cb(400) if err?
            return cb(403) if player.id isnt post.poster_id
            @db.deletePost data.postId, (err, result) =>
                return cb(400) if err?
                return cb(200)

    deletePostData: (player, data, cb) ->
        @db.getPost data.postId, (err, post) =>
            return cb(400) if err?
            return cb(403) if player.id isnt post.poster_id
            @db.deletePostData data.postId, (err, result) =>
                return cb(400) if err?
                @deleteNotification player, { notifierId: player.id, postId: data.postId, type: 1 }, cb

    deleteLike: (player, data, cb) ->
        @db.getLike player.id, data.postId, (err, like) =>
            return cb(403) if err?
            @db.deleteLike player.id, data.postId, (err, result) =>
                return cb(400) if err?
                @deleteNotification player, { notifierId: player.id, postId: data.postId, type: 2 }, cb


    getNotifications: (player, data, cb) ->
        @db.getNotifications player.id, (err, notifications) =>
            return cb(400) if err?
            return cb { notifications: notifications }

    createNotification: (player, data, cb) ->
        @db.createNotification data.playerId, data.notifierId, data.postId, data.type, data.content or '', (err, result) =>
            return cb(400) if err?
            return cb(200)

    createMessageNotification: (player, data, cb) ->
        @db.createNotification data.playerId, data.notifierId, null, 3, data.content, (err, result) =>
            return cb(400) if err?
            return cb(200)

    updateNotification: (player, data, cb) ->
        # get notification first and check if players match
        @db.getNotification data.notificationId, (err, notification) =>
            return cb(400) if err?
            return cb(403) if player.id isnt notification.player_id
            @db.updateNotification data.notificationId, (err, result) =>
                return cb(400) if err?
                return cb(200)

    updateNotificationHidden: (player, data, cb) ->
        # get notification first and check if players match
        @db.getNotification data.notificationId, (err, notification) =>
            return cb(400) if err?
            return cb(403) if player.id isnt notification.player_id
            @db.updateNotificationHidden data.notificationId, (err, result) =>
                return cb(400) if err?
                return cb(200)

    deleteNotification: (player, data, cb) ->
        @db.deleteNotification data.notifierId, data.postId, data.type, (err, result) =>
            return cb(400) if err?
            return cb(200)

