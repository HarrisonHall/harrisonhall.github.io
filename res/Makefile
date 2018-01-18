all: 
	mkdir -p release
	mkdir -p logs
	cp package_linux.json release/package.json
	cd release && npm install
	cat server/Common.coffee server/Room.coffee server/Lobby.coffee server/Game.coffee server/FixedGame.coffee server/TrumpGame.coffee server/PercivalGame.coffee server/Player.coffee server/Database_Postgres.coffee server/StatisticsWorker.coffee server/StatisticsWorkers.coffee server/Statistics.coffee server/Bans.coffee server/Rating.coffee server/Commands.coffee server/Tokens.coffee server/Discussions.coffee server/Main.coffee | coffee --compile --stdio > release/Server.js
	cp -rf client release/client

clean:
	rm -rf release

cleanr:
	rm -rf release/client
	rm -rf release/server

test: all
	cat server/Room.coffee server/Game.coffee server/Player.coffee server/Database_Postgres.coffee server/Lobby.coffee server/Test.coffee | coffee --compile --stdio > release/Test.js
	node release/Test.js
