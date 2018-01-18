## Getting Started (Linux/Postgres)

#### Optional: Set up [nodeenv](http://ekalinin.github.io/nodeenv/) and enter the environment
#### Install dependencies

* Install [Node.JS](https://nodejs.org/en/)
* If needed due to a conflict, symlink /usr/bin/node to /usr/bin/nodejs: ``sudo ln -s `which nodejs` /usr/bin/node``
* From the command line, run `npm install -g coffee-script` to install CoffeeScript. 
* Install [PostgreSQL](https://www.postgresql.org/download/)

#### Create a Postgres database

Any one will do. A simple pattern for doing it at home (Debian-ish) is:

```
$ sudo su postgres
$ psql
postgres=# CREATE USER mypguser WITH PASSWORD 'mypguserpass';
postgres=# CREATE DATABASE mypgdatabase OWNER mypguser;
postgres=# \q
$ exit
```

#### Set up DB tables

```
$ psql -h localhost -U mypguser -d mypgdatabase
Password for user mypguser:
psql (9.4.2, server 9.3.4)
SSL connection (protocol: TLSv1.2, cipher: DHE-RSA-AES256-GCM-SHA384, bits: 256, compression: off)
Type "help" for help.

mypgdatabase=> \i misc/recreatedb_pg.sql
mypgdatabase=> \q
```

#### Set the environment variables
This name of this .json file is an argument to the program. By default the file is sample_options.json.

```
{
    "port": 8080,
    "db_connection_string": "postgres://mypguser:mypguserpass@localhost/mypgdatabase"
}
```

Or equivalent for your choice of hostname, user, password and database name above.

#### Build

```
make
```

#### Run

```
node release/Server.js sample_options.json
```

And connect on [http://localhost:8080](http://localhost:8080)


## Overview

After logging in, the client is assigned a "session key" as a cookie.  This session key must be sent by the client in subsequent messages.

The client sends messages with the PUT verb at /server/play, and receives messages at the same endpoint with GET. Every message is a JSON hash, the type of message indicated by the field "cmd".

If no messages are available, then GET is a long poll; the request will block up until 90 seconds or until a new message is available.

On the server, all globals are kept in the "g" hash (defined in Lobby.coffee).  At present, g contains:

* **playersById**: a list of Player objects (defined in Player.coffee), representing currently logged-in users, indexed by their database ID.
* **playersBySessionKey**: the same list of Player objects, this time indexed by session key.
* **db**: a Database object, defined in Database.coffee, which encapsulates all database access.
* **lobby**: the main Lobby room.

Every player has a player ID. This is the same ID of the user as stored in the database. Messages typically refer to players by ID, not by name.

The `Player::send()` method enqueues a message to send to the user. This list of pending messages is sent out when the `Player::flush()` method is called. If the client has no long-poll open when `Player::flush()` is called, then `Player::flush()` is a no-op.

Players are organized into *Rooms*. There are currently two types of Rooms: Lobby and Game.  When a client sends a message to the server, the message is routed to that user's Room for processing.  Typically this will result in multiple calls to `Player::send()` in order to enqueue new messages to other players.  When a Room finishes processing a client message, it calls `Player::flush()` on all users in that room.  Also, Rooms force a flush for every player in that room every 90 seconds (so that long-polls don't TCP/IP timeout).

In Game.coffee, pending player actions are referred to as "questions".  Each question has a corresponding choiceId.  When a user responds to a question, they send back the choiceId of the question they are responding to.  Users can respond to questions in any order.

The `Game::askOne()` method sends a question to a player. Every question has an associated callback function which is invoked when the player responds.

The `Game::ask()` method asks a list of questions in parallel.  This method takes a callback function which is invoked when all questions have been answered. `Game::ask()` also updates the status message each time a question is answered.

In Main.coffee, players are garbage collected (and logged out) after ten minutes of inactivity.

### Testing Changes

Sorry, there's no comprehensive test suite.  However, it is fairly easy to exercise your changes using two tools:

* **misc\Bot.coffee**: This instantiates a bunch of robot players that try to join an existing game (or, rarely, create new games of their own). These bots play randomly.
* **Test.coffee**: For more targetted tests of specific, hard-to-reach scenarios, you can instantiate a Game object, mock out Lobby and Database objects that it uses, then programmatically simulate the receipt of user commands. You can then inspect the received commands in each player's queue. See Test.coffee for an example of how to do this.
