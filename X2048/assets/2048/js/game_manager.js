function GameManager(size, InputManager, Actuator, StorageManager) {
	this.size = size; // 棋盘大小
	this.inputManager = new InputManager; // 输入管理器
	this.storageManager = new StorageManager; // 得分管理器
	this.actuator = new Actuator; // HTML呈现

	this.startTiles = 2;

	this.inputManager.on("move", this.move.bind(this));
	this.inputManager.on("restart", this.restart.bind(this));
	this.inputManager.on("keepPlaying", this.keepPlayingf.bind(this));

	this.undoStack = []; // UNDO栈
	this.setup();
}

// 重起游戏
GameManager.prototype.restart = function() {
	this.storageManager.clearGameState();
	this.actuator.continueGame(); // 清除游戏胜利、失败消息
	this.setup();
};

// 继续游戏,在达到2048后继续.
GameManager.prototype.keepPlayingf = function() {
	this.keepPlaying = true;
	this.actuator.continueGame(); // Clear the game won/lost message
};

// Return true if the game is lost, or has won and the user hasn't kept playing
GameManager.prototype.isGameTerminated = function() {
	// 游戏结束判定标准:
	/*
	 * over： 游戏结束，即已经满屏且没有可合并的方块 ！（won且选择继续）
	 */
	return this.over || (this.won && !this.keepPlaying);
};

// 开始游戏,设置初始布局
GameManager.prototype.setup = function() {
	var previousState = this.storageManager.getGameState();

	// 如果此项有值,证明已经有保存的游戏进度
	if (previousState) {
		this.grid = new Grid(previousState.grid.size, previousState.grid.cells);
		this.score = previousState.score;
		this.over = previousState.over;
		this.won = previousState.won;
		this.undoStack = previousState.undo ? previousState.undo : [];
		this.keepPlaying = previousState.keepPlaying;
	} else {
		this.grid = new Grid(this.size);
		this.score = 0;
		this.over = false;
		this.won = false;
		this.undoStack = [];
		this.keepPlaying = false;

		// 添加初始方块，参见line #7
		this.addStartTiles();
	}

	this.actuate();
};

// 设置游戏的初始状态
GameManager.prototype.addStartTiles = function() {
	for (var i = 0; i < this.startTiles; i++) {
		this.addRandomTile();
	}
};

// 向一个随机的位置添加方块
GameManager.prototype.addRandomTile = function() {
	if (this.grid.cellsAvailable()) {
		var value = Math.random() < 0.9 ? 2 : 4;// 90%的概率放入2,10%的概率放入4
		var tile = new Tile(this.grid.randomAvailableCell(), value);// 在一个随机的空位置放入
		this.grid.insertTile(tile);// 插入方块
	}
};

// 更新游戏状态到呈现器
GameManager.prototype.actuate = function() {
	if (this.storageManager.getBestScore() < this.score) {
		this.storageManager.setBestScore(this.score);
	}

	if (this.over) {
		// 如果游戏结束，清空保存的游戏状态。
		this.storageManager.clearGameState();
	} else {
		// 否则,将当前游戏状态写入存储 TODO:此处可能影响性能,可以改为将游戏状态存入一个变量,等游戏结束或者离开页面时再写入.
		this.storageManager.setGameState(this.serialize());
	}

	this.actuator.actuate(this.grid, {
		score : this.score,
		over : this.over,
		won : this.won,
		bestScore : this.storageManager.getBestScore(),
		terminated : this.isGameTerminated()
	});

};

// Represent the current game as an object
GameManager.prototype.serialize = function() {
	return {
		grid : this.grid.serialize(),
		score : this.score,
		over : this.over,
		won : this.won,
		keepPlaying : this.keepPlaying,
		undo : this.undoStack
	};
};

// Save all tile positions and remove merger info
GameManager.prototype.prepareTiles = function() {
	this.grid.eachCell(function(x, y, tile) {
		if (tile) {
			tile.mergedFrom = null;
			tile.savePosition();
		}
	});
};

// Move a tile and its representation
// 移动一个方块
GameManager.prototype.moveTile = function(tile, cell) {
	this.grid.cells[tile.x][tile.y] = null;
	this.grid.cells[cell.x][cell.y] = tile;
	tile.updatePosition(cell);
};

// Move tiles on the grid in the specified direction
GameManager.prototype.move = function(direction) {
	// 0: up, 1: right, 2:down, 3: left, -1: undo
	var self = this;
	//
	// if (this.isGameTerminated())
	// return; // 如果游戏已经结束,就不再执行任何操作

	if (direction === -1) {
		if (!app.undo) {
			app.send("req", "undo")
			// 未购买,弹出提示,退出
			return;
		}
		if (this.undoStack.length > 0) {
			// 已购买,且可后退.
			var prev = this.undoStack.pop();

			this.grid.build();
			this.score = prev.score;
			for ( var i in prev.tiles) {
				var t = prev.tiles[i];
				var tile = new Tile({
					x : t.x,
					y : t.y
				}, t.value);
				tile.previousPosition = {
					x : t.previousPosition.x,
					y : t.previousPosition.y
				};
				this.grid.cells[tile.x][tile.y] = tile;
			}
			this.over = false;// 未结束
			this.won = false;// 未胜利
			this.keepPlaying = false;// 原因不明
			this.actuator.continueGame();
			this.actuate();
		}
		return;
	}

	var cell, tile;
	var vector = this.getVector(direction);
	var traversals = this.buildTraversals(vector);
	var moved = false;
	var undo = {
		score : this.score,
		tiles : []
	};

	// Save the current tile positions and remove merger information
	this.prepareTiles();

	// Traverse the grid in the right direction and move tiles
	traversals.x.forEach(function(x) {
		traversals.y.forEach(function(y) {
			cell = {
				x : x,
				y : y
			};
			tile = self.grid.cellContent(cell);

			if (tile) {
				var positions = self.findFarthestPosition(cell, vector);
				var next = self.grid.cellContent(positions.next);

				// Only one merger per row traversal?
				if (next && next.value === tile.value && !next.mergedFrom) {
					// We need to save tile since it will get removed
					undo.tiles.push(tile.save(positions.next));

					var merged = new Tile(positions.next, tile.value * 2);
					merged.mergedFrom = [ tile, next ];

					self.grid.insertTile(merged);
					self.grid.removeTile(tile);

					// Converge the two tiles' positions
					tile.updatePosition(positions.next);

					// Update the score
					self.score += merged.value;

					// The mighty 2048 tile
					if (merged.value === 2048)
						self.won = true;
				} else {
					// Save backup information
					undo.tiles.push(tile.save(positions.farthest));
					self.moveTile(tile, positions.farthest);
				}

				if (!self.positionsEqual(cell, tile)) {
					moved = true; // The tile moved from its original cell!
				}
			}
		});
	});

	if (moved) {
		// 如果发生了移动,就加入一个随机方块
		this.addRandomTile();

		if (!this.movesAvailable()) {
			this.over = true; // 如果已经没有可以合并的方块,游戏结束
		}

		// Save state
		// if (app.undo) {
		if (this.undoStack.length >= 50) {
			this.undoStack.shift();
		}
		this.undoStack.push(undo);
		// }

		this.actuate();
	}
};

// Get the vector representing the chosen direction
GameManager.prototype.getVector = function(direction) {
	// Vectors representing tile movement
	var map = {
		0 : {
			x : 0,
			y : -1
		},
		// Up
		1 : {
			x : 1,
			y : 0
		},
		// Right
		2 : {
			x : 0,
			y : 1
		},
		// Down
		3 : {
			x : -1,
			y : 0
		}
	// Left
	};

	return map[direction];
};

// Build a list of positions to traverse in the right order
GameManager.prototype.buildTraversals = function(vector) {
	var traversals = {
		x : [],
		y : []
	};

	for (var pos = 0; pos < this.size; pos++) {
		traversals.x.push(pos);
		traversals.y.push(pos);
	}

	// Always traverse from the farthest cell in the chosen direction
	if (vector.x === 1)
		traversals.x = traversals.x.reverse();
	if (vector.y === 1)
		traversals.y = traversals.y.reverse();

	return traversals;
};

GameManager.prototype.findFarthestPosition = function(cell, vector) {
	var previous;

	// Progress towards the vector direction until an obstacle is found
	do {
		previous = cell;
		cell = {
			x : previous.x + vector.x,
			y : previous.y + vector.y
		};
	} while (this.grid.withinBounds(cell) && this.grid.cellAvailable(cell));

	return {
		farthest : previous,
		next : cell
	// Used to check if a merge is required
	};
};

GameManager.prototype.movesAvailable = function() {
	return this.grid.cellsAvailable() || this.tileMatchesAvailable();
};

// Check for available matches between tiles (more expensive check)
GameManager.prototype.tileMatchesAvailable = function() {
	var self = this;

	var tile;

	for (var x = 0; x < this.size; x++) {
		for (var y = 0; y < this.size; y++) {
			tile = this.grid.cellContent({
				x : x,
				y : y
			});

			if (tile) {
				for (var direction = 0; direction < 4; direction++) {
					var vector = self.getVector(direction);
					var cell = {
						x : x + vector.x,
						y : y + vector.y
					};
					var other = self.grid.cellContent(cell);
					if (other && other.value === tile.value) {
						return true; // These two tiles can be merged
					}
				}
			}
		}
	}

	return false;
};

GameManager.prototype.positionsEqual = function(first, second) {
	return first.x === second.x && first.y === second.y;
};

Function.prototype.bind = Function.prototype.bind || function(target) {
	var self = this;
	return function(args) {
		if (!(args instanceof Array)) {
			args = [ args ];
		}
		self.apply(target, args);
	};
};

(function() {
	if (typeof window.Element === "undefined"
			|| "classList" in document.documentElement) {
		return;
	}

	var prototype = Array.prototype, push = prototype.push, splice = prototype.splice, join = prototype.join;

	function DOMTokenList(el) {
		this.el = el;
		// The className needs to be trimmed and split on whitespace
		// to retrieve a list of classes.
		var classes = el.className.replace(/^\s+|\s+$/g, '').split(/\s+/);
		for (var i = 0; i < classes.length; i++) {
			push.call(this, classes[i]);
		}
	}

	DOMTokenList.prototype = {
		add : function(token) {
			if (this.contains(token))
				return;
			push.call(this, token);
			this.el.className = this.toString();
		},
		contains : function(token) {
			return this.el.className.indexOf(token) != -1;
		},
		item : function(index) {
			return this[index] || null;
		},
		remove : function(token) {
			if (!this.contains(token))
				return;
			for (var i = 0; i < this.length; i++) {
				if (this[i] == token)
					break;
			}
			splice.call(this, i, 1);
			this.el.className = this.toString();
		},
		toString : function() {
			return join.call(this, ' ');
		},
		toggle : function(token) {
			if (!this.contains(token)) {
				this.add(token);
			} else {
				this.remove(token);
			}

			return this.contains(token);
		}
	};

	window.DOMTokenList = DOMTokenList;

	function defineElementGetter(obj, prop, getter) {
		if (Object.defineProperty) {
			Object.defineProperty(obj, prop, {
				get : getter
			});
		} else {
			obj.__defineGetter__(prop, getter);
		}
	}

	defineElementGetter(HTMLElement.prototype, 'classList', function() {
		return new DOMTokenList(this);
	});
})();

function Grid(size, previousState) {
	this.size = size;
	this.cells = previousState ? this.fromState(previousState) : this.empty();
}
// Build a grid of the specified size
Grid.prototype.build = function() {
	for (var x = 0; x < this.size; x++) {
		var row = this.cells[x] = [];

		for (var y = 0; y < this.size; y++) {
			row.push(null);
		}
	}
};
// Build a grid of the specified size
Grid.prototype.empty = function() {
	var cells = [];

	for (var x = 0; x < this.size; x++) {
		var row = cells[x] = [];

		for (var y = 0; y < this.size; y++) {
			row.push(null);
		}
	}

	return cells;
};

Grid.prototype.fromState = function(state) {
	var cells = [];

	for (var x = 0; x < this.size; x++) {
		var row = cells[x] = [];

		for (var y = 0; y < this.size; y++) {
			var tile = state[x][y];
			row.push(tile ? new Tile(tile.position, tile.value) : null);
		}
	}

	return cells;
};

// Find the first available random position
Grid.prototype.randomAvailableCell = function() {
	var cells = this.availableCells();

	if (cells.length) {
		return cells[Math.floor(Math.random() * cells.length)];
	}
};

Grid.prototype.availableCells = function() {
	var cells = [];
	// 试图修正快速移动时误判游戏结束的情况
	for (var x = 0; x < this.size; x++) {
		for (var y = 0; y < this.size; y++) {
			if (!this.cells[x][y]) {
				cells.push({
					x : x,
					y : y
				});
			}
		}
	}
	// console.log("availableCells" + JSON.stringify(cells));
	return cells;
};

// Call callback for every cell
Grid.prototype.eachCell = function(callback) {
	for (var x = 0; x < this.size; x++) {
		for (var y = 0; y < this.size; y++) {
			callback(x, y, this.cells[x][y]);
		}
	}
};

// Check if there are any cells available
Grid.prototype.cellsAvailable = function() {
	return !!this.availableCells().length;
};

// Check if the specified cell is taken
Grid.prototype.cellAvailable = function(cell) {
	return !this.cellOccupied(cell);
};

Grid.prototype.cellOccupied = function(cell) {
	return !!this.cellContent(cell);
};

Grid.prototype.cellContent = function(cell) {
	if (this.withinBounds(cell)) {
		return this.cells[cell.x][cell.y];
	} else {
		return null;
	}
};

// Inserts a tile at its position
Grid.prototype.insertTile = function(tile) {
	this.cells[tile.x][tile.y] = tile;
};

Grid.prototype.removeTile = function(tile) {
	this.cells[tile.x][tile.y] = null;
};

Grid.prototype.withinBounds = function(position) {
	return position.x >= 0 && position.x < this.size && position.y >= 0
			&& position.y < this.size;
};

Grid.prototype.serialize = function() {
	var cellState = [];

	for (var x = 0; x < this.size; x++) {
		var row = cellState[x] = [];

		for (var y = 0; y < this.size; y++) {
			row.push(this.cells[x][y] ? this.cells[x][y].serialize() : null);
		}
	}

	return {
		size : this.size,
		cells : cellState
	};
};

function HTMLActuator() {
	this.tileContainer = document.querySelector(".tile-container");
	this.scoreContainer = document.querySelector(".score-container");
	this.bestContainer = document.querySelector(".best-container");
	this.messageContainer = document.querySelector(".game-message");
	this.sharingContainer = document.querySelector(".score-sharing");
	this.score = 0;
}

HTMLActuator.prototype.actuate = function(grid, metadata) {
	var self = this;
	window.webkitRequestAnimationFrame(function() {
		self.clearContainer(self.tileContainer);// 清空全部的tile

		grid.cells.forEach(function(column) {
			column.forEach(function(cell) {
				if (cell) {
					self.addTile(cell);
				}
			});
		});
		self.updateBestScore(metadata.bestScore);
		self.updateScore(metadata.score,metadata.bestScore);

		if (metadata.terminated) {
			console.log("Game Terminated:" + JSON.stringify(metadata));
			if (metadata.over) {
				self.message(false); // 挂了
			} else if (metadata.won) {
				self.message(true); // 胜利
			}
		}

	});
};

// Continues the game (both restart and keep playing)
HTMLActuator.prototype.continueGame = function() {
	this.clearMessage();
	// 清空游戏结束信息
};

HTMLActuator.prototype.clearContainer = function(container) {
	while (container.firstChild) {
		container.removeChild(container.firstChild);
	}
};

HTMLActuator.prototype.addTile = function(tile) {
	var self = this;

	var wrapper = document.createElement("div");
	var inner = document.createElement("div");
	var position = tile.previousPosition || {
		x : tile.x,
		y : tile.y
	};
	var positionClass = this.positionClass(position);

	// We can't use classlist because it somehow glitches when replacing classes
	var classes = [ "tile", "tile-" + tile.value, positionClass ];

	if (tile.value > 2048)
		classes.push("tile-super");

	this.applyClasses(wrapper, classes);

	inner.classList.add("tile-inner");
	inner.textContent = tile.value;

	if (tile.previousPosition) {
		// Make sure that the tile gets rendered in the previous position first
		window.webkitRequestAnimationFrame(function() {
			classes[2] = self.positionClass({
				x : tile.x,
				y : tile.y
			});
			self.applyClasses(wrapper, classes); // Update the position
		});
	} else if (tile.mergedFrom) {
		// window.webkitRequestAnimationFrame(function() {
		classes.push("tile-merged");
		self.applyClasses(wrapper, classes);

		// Render the tiles that merged
		tile.mergedFrom.forEach(function(merged) {
			self.addTile(merged);
		});
		// })
	} else {
		// window.webkitRequestAnimationFrame(function() {
		classes.push("tile-new");
		self.applyClasses(wrapper, classes);
		// })
	}
	// window.webkitRequestAnimationFrame(function() {
	// Add the inner part of the tile to the wrapper
	wrapper.appendChild(inner);

	// Put the tile on the board
	self.tileContainer.appendChild(wrapper);
	// })
};

HTMLActuator.prototype.applyClasses = function(element, classes) {
	element.setAttribute("class", classes.join(" "));
};

HTMLActuator.prototype.normalizePosition = function(position) {
	return {
		x : position.x + 1,
		y : position.y + 1
	};
};

HTMLActuator.prototype.positionClass = function(position) {
	position = this.normalizePosition(position);
	return "tile-position-" + position.x + "-" + position.y;
};

HTMLActuator.prototype.updateScore = function(score,bscore) {
	this.clearContainer(this.scoreContainer);

	var difference = score - this.score;
	this.score = score;

	this.scoreContainer.textContent = this.score;

	if (difference > 0) {
		// var addition = document.createElement("div");
		// addition.classList.add("score-addition");
		// addition.textContent = "+" + difference;
		// this.scoreContainer.appendChild(addition);
		app.send("audio", "high");
		app.send('updatescore', {
			'cur' : score,
			'best' : bscore
		});
	} else {
		app.send("audio", "low");
	}
};

HTMLActuator.prototype.updateBestScore = function(bestScore) {
	this.bestContainer.textContent = bestScore;
};

HTMLActuator.prototype.message = function(won) {
	if (won && app.gamemgr.keepPlaying) {
		// bypass
	} else {
		app.send("gameover", {
			"win" : won,
			"score" : this.score,
			"best" : this.bestContainer.textContent
		});
	}

	/*
	 * var type = won ? "game-won" : "game-over"; var message = won ?
	 * i18n.get('win', app.lang) : i18n.get('over', app.lang); if (app.useAudio) {
	 * PGLowLatencyAudio.play("win.wav", function(echoValue) { }); } setTimeout(
	 * function() { app.gamemgr.actuator.messageContainer.classList.add(type);
	 * app.gamemgr.actuator.messageContainer.getElementsByTagName("p")[0].textContent =
	 * message; }, 666);
	 */
};

HTMLActuator.prototype.clearMessage = function() {
};
function tweetscore(score) {
}
// //////////////////////////////////
function KeyboardInputManager() {
	this.events = {};

	this.eventTouchstart = "touchstart";
	this.eventTouchmove = "touchmove";
	this.eventTouchend = "touchend";

	this.listen();
}

KeyboardInputManager.prototype.on = function(event, callback) {
	if (!this.events[event]) {
		this.events[event] = [];
	}
	this.events[event].push(callback);
};

KeyboardInputManager.prototype.emit = function(event, data) {
	var callbacks = this.events[event];
	if (callbacks) {
		callbacks.forEach(function(callback) {
			callback(data);
		});
	}
};
KeyboardInputManager.prototype.tweetit = function() {
	tweetscore(app.gamemgr.score);
};
KeyboardInputManager.prototype.listen = function() {
	var self = this;

	var map = {
		38 : 0,
		// Up
		39 : 1,
		// Right
		40 : 2,
		// Down
		37 : 3,
		// Left

		75 : 0,
		// Vim up
		76 : 1,
		// Vim right
		74 : 2,
		// Vim down
		72 : 3,
		// Vim left

		87 : 0,
		// W
		68 : 1,
		// D
		83 : 2,
		// S
		65 : 3,
		// // A
		90 : -1
	// Z (undo)
	};

	// Respond to direction keys
	document.onkeydown = function(event) {
		var modifiers = event.altKey || event.ctrlKey || event.metaKey
				|| event.shiftKey;
		var mapped = map[event.which];

		if (!modifiers) {
			if (mapped !== undefined) {
				event.preventDefault();
				self.emit("move", mapped);
			}
		}

		// R key restarts the game
		if (!modifiers && event.which === 82) {
			self.restart.call(self, event);
		}
	};

	// Respond to button presses
	this.bindButtonPress(".retry-button", this.restart);
	this.bindButtonPress('#undobtn', undoHandler);
	// this.bindButtonPress(".title", this.restart);
	// this.bindButtonPress(".keep-playing-button", this.keepPlayingf);
	// this.bindButtonPress(".score-sharing", this.tweetit);
	// Respond to swipe events
	var touchStartClientX, touchStartClientY;
	// var gameContainer = document.getElementsByClassName("game-container")[0];
	var gameContainer = document;// .getElementById("gamescr");

	gameContainer.ontouchstart = function(event) {
		if ((event.touches.length > 1) || event.targetTouches > 1) {
			return; // Ignore if touching with more than 1 finger
		}

		touchStartClientX = event.touches[0].clientX;
		touchStartClientY = event.touches[0].clientY;

		event.preventDefault();
	};

	gameContainer.ontouchmove = function(event) {
		event.preventDefault();
	};

	gameContainer.ontouchend = function(event) {
		if ((event.touches.length > 0) || event.targetTouches > 0) {
			return; // Ignore if still touching with one or more fingers
		}

		var touchEndClientX, touchEndClientY;

		touchEndClientX = event.changedTouches[0].clientX;
		touchEndClientY = event.changedTouches[0].clientY;

		var dx = touchEndClientX - touchStartClientX;
		var absDx = Math.abs(dx);

		var dy = touchEndClientY - touchStartClientY;
		var absDy = Math.abs(dy);

		if (Math.max(absDx, absDy) > 30) {
			// (right : left) : (down : up)
			self.emit("move", absDx > absDy ? (dx > 0 ? 1 : 3) : (dy > 0 ? 2
					: 0));
		}
	};
};

KeyboardInputManager.prototype.restart = function(event) {
	event.preventDefault();
	app.send("req", "restart");
};

KeyboardInputManager.prototype.keepPlaying = function(event) {
	event.preventDefault();
	this.emit("keepPlaying");
};

KeyboardInputManager.prototype.bindButtonPress = function(selector, fn) {
	var button = document.querySelector(selector);
	button.onclick = fn.bind(this);
	button.ontouchend = fn.bind(this);
};

window.fakeStorage = {
	_data : {},
	setItem : function(id, val) {
		return this._data[id] = String(val);
	},
	getItem : function(id) {
		return this._data.hasOwnProperty(id) ? this._data[id] : undefined;
	},
	removeItem : function(id) {
		return delete this._data[id];
	},
	clear : function() {
		return this._data = {};
	}
};

function LocalStorageManager() {
	this.bestScoreKey = "bestScore";
	this.gameStateKey = "gameState";
	this.cache = null;

	var supported = this.localStorageSupported();
	this.storage = supported ? window.localStorage : window.fakeStorage;
}

LocalStorageManager.prototype.localStorageSupported = function() {
	return true;
};

// Best score getters/setters
LocalStorageManager.prototype.getBestScore = function() {
	return this.storage.getItem(this.bestScoreKey) || 0;
};

LocalStorageManager.prototype.setBestScore = function(score) {
	this.storage.setItem(this.bestScoreKey, score);
};

// Game state getters/setters and clearing
LocalStorageManager.prototype.getGameState = function() {
	if (!this.cache) {
		var stateJSON = this.storage.getItem(this.gameStateKey);
		this.cache = stateJSON ? JSON.parse(stateJSON) : null;
		console.warn('Read LocalStorage');
	}
	return this.cache;
};

LocalStorageManager.prototype.setGameState = function(gameState) {
	this.cache = gameState;
};
LocalStorageManager.prototype.flush = function() {
	if (this.cache) {
		console.warn('Write LocalStorage');
		this.storage.setItem(this.gameStateKey, JSON.stringify(this.cache));
	}
};

LocalStorageManager.prototype.clearGameState = function() {
	this.cache = null;
	this.storage.removeItem(this.gameStateKey);
	console.warn('Clear LocalStorage');
};

function Tile(position, value) {
	this.x = position.x;
	this.y = position.y;
	this.value = value || 2;

	this.previousPosition = null;
	this.mergedFrom = null; // Tracks tiles that merged together
}

Tile.prototype.savePosition = function() {
	this.previousPosition = {
		x : this.x,
		y : this.y
	};
};

Tile.prototype.updatePosition = function(position) {
	this.x = position.x;
	this.y = position.y;
};

Tile.prototype.serialize = function() {
	return {
		position : {
			x : this.x,
			y : this.y
		},
		value : this.value
	};
};

Tile.prototype.save = function(next) {
	var copy = {};
	copy.x = this.x;
	copy.y = this.y;
	copy.value = this.value;
	copy.previousPosition = {
		x : next.x,
		y : next.y
	};
	return copy;
};