var app = {
	initialize : function() {
		document.querySelector('meta[name=viewport]').content = "initial-scale="
				+ screen.availWidth / 660;
		this.bindEvents();
		var them = localStorage.getItem("theme");
		if (them) {
			document.body.className = them;
		}
	},
	bindEvents : function() {
		window.onload = function() {
			navigator.cascades.onmessage = function(message) {
				app.onMessageReceived(message);
			};
			app.onDeviceReady();
		};
		window.onunload = function() {
			app.saveState();
		};
	},
	onMessageReceived : function(message) {
		var msg = JSON.parse(message);
		console.log(msg);
		if (msg.type === "init") {

			app.lang = msg.content.lang ? msg.content.lang : "";

			if (msg.content.undo === "true") {
				app.undo = true;
				localStorage.setItem('undo', 'true');
			} else {
				app.undo = false;
				localStorage.setItem('undo', 'false');
			}
			if (msg.content.theme) {
				app.theme = msg.content.theme;
				localStorage.setItem("theme", app.theme);
			}
			if (msg.content.speed) {
				app.speed = msg.content.speed;
			}

			app.init();
		} else if (msg.type === "save") {
			app.saveState();
		} else if (msg.type === "move") {
			var direction = parseInt(msg.content);
			app.gamemgr.move(direction);
		} else if (msg.type === "undo") {
			app.gamemgr.move(-1);
		} else if (msg.type === "reset") {
			app.gamemgr.storageManager.setBestScore(0);
			app.gamemgr.storageManager.clearGameState();
			app.send('updatescore', {
				'cur' : 0,
				'best' : 0
			});
		} else if (msg.type === "newgame") {
			app.gamemgr.restart();
		} else if (msg.type === "continue") {
			app.gamemgr.keepPlayingf();
		} else if (msg.type === "update") {
			var data = JSON.parse(msg.data);
			app.gamemgr.storageManager.setBestScore(data.bestScore);
			console.log("data.bestScore:" + data.bestScore);
			app.gamemgr.storageManager.setGameState(data);
			console.log('data:' + data);
			app.gamemgr.storageManager.flush();
			document.location.reload();
		}
	},
	saveState : function() {
		if (app.gamemgr) {
			app.gamemgr.storageManager.flush();
		}
	},
	onDeviceReady : function() {
		app.receivedEvent('deviceready');
	},
	// Update DOM on a Received Event
	receivedEvent : function(id) {
		console.log('Received Event: ' + id);
		app.send("event", 'ready');
	},
	send : function(type, content) {
		navigator.cascades.postMessage(JSON.stringify({
			"type" : type,
			"content" : content
		}));
	},
	gamemgr : null,
	lang : localStorage.getItem('lang') ? localStorage.getItem('lang') : "",
	theme : localStorage.getItem('theme') ? localStorage.getItem('theme')
			: "bright",
	speed : localStorage.getItem('speed') ? localStorage.getItem('speed')
			: "normal",
	undo : localStorage.getItem('undo') === 'true',
	init : function() {
		i18n.process(document, app.lang);
		document.body.className = app.speed + " " + app.theme;
		if (!app.gamemgr) {
			window.webkitRequestAnimationFrame(function() {
				app.gamemgr = new GameManager(4, KeyboardInputManager,
						HTMLActuator, LocalStorageManager);
			});
		}
		app.send("event", 'init_done');
	}
};
/*
 * "digitalGoodSKU": "2048_undo", "digitalGoodName": "Undo"
 */

function undoHandler(event) {
	event.preventDefault();
	app.gamemgr.move(-1);
}