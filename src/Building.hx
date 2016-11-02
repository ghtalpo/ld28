import Const;

typedef Action = { item : Item, ?enable : Void -> Bool, text : String, callb : Void -> Void, ?ui : { i : h2d.Interactive, tf : h2d.Text } };

class Building {

	public var visible : Bool = true;
	public var kind : Const.BuildingKind;
	var game : Game;
	var dialog : h2d.Sprite;
	var actions : Array<Action>;
	public var clickCount : Int;
	public var pending : {
		time : Float,
		max : Float,
		callb : Void -> Void,
		mc : h2d.Sprite,
		bar : h2d.Sprite,
	};

	public function new(kind) {
		this.kind = kind;
		this.game = Game.inst;
	}

	function getActions() : Array<Action> {
		return [];
	}

	function unlock(b) {
		game.unlockBuilding(b);
	}

	function getTexts() {
		return ["NO INTRO", "NO TEXT"];
	}

	function spawn( i : Item ) {
		var it = new h2d.Bitmap(game.items[i.getIndex()]);
		game.scene.add(it, 5);

		it.colorKey = 0;

		var pos = Texts.BUILDPOS(kind);
		var x : Float = pos[4] * 16 + pos[6] * 8, y : Float = pos[5] * 16 + pos[7] * 8;
		x -= 5;
		y -= 5;
		if( i == Seed ) {
			x += Std.random(16) - 8;
			y += Std.random(16) - 8;
		}
		var sy = y;
		var step = 0;
		var u = new Update();
		it.x = x; it.y = y;
		var time = 0.;
		u.update = function(dt) {
			time += dt;
			switch( step ) {
			case 0:
				if( time > 40 ) {
					time = 0;
					step++;
				}
			case 1:
				var tx = i.getIndex() * 13;
				var ty = Const.H + 1;
				var dx = tx - x;
				var dy = ty - y;
				var d = Math.sqrt(dx * dx + dy * dy);
				var mv = time * 0.5 * dt;
				if( d > mv ) {
					dx *= mv / d;
					dy *= mv / d;
				} else {
					time = 0;
					step++;
				}
				x += dx;
				y += dy;
			case 2:
				if( time > 10 ) {
					u.stop();
					it.remove();
					if( game.checkAdd(i) )
						game.add(i);
				}
			}
			it.x = Std.int(x * 2) / 2;
			it.y = Std.int((y + Math.sin(time * 0.5)) * 2) / 2;
		};
	}

	function start(time, callb ) {
		if( pending != null ) throw "assert";

		var mc = new h2d.Sprite();
		var bg = new h2d.Bitmap(h2d.Tile.fromColor(0xC0000000, 34, 4), mc);
		new h2d.Bitmap(h2d.Tile.fromColor(0xFFFF0000, 32, 2), mc);
		bg.x = bg.y = -1;
		var bar = new h2d.Bitmap(h2d.Tile.fromColor(0xFF00FF00,1,2), mc);
		var pos = Texts.BUILDPOS(kind);


		game.world.root.addChild(mc);
		mc.x = (pos[4] * 16 + pos[6] * 8) - 16;
		mc.y = pos[5] * 16;

		if( kind == BWheat )
			mc.y += 16;

		pending = {
			time : 0.,
			max : time,
			callb : callb,
			mc : mc,
			bar : bar,
		};
	}

	public function update(dt:Float) {
		if( pending != null ) {
			pending.time += (dt / 60) * (Game.DEBUG ? 10 : 1);
			pending.bar.scaleX = 29 * pending.time / pending.max;
			if( pending.time >= pending.max ) {
				var c = pending.callb;
				pending.mc.remove();
				pending = null;
				Res.sfx.done.play();
				c();
			}
		}
	}

	function done() {
	}

	function addAction( a : Action ) {
		var spr = game.newPanel(100, 20);
		dialog.addChild(spr);
		var px = 10;
		if( a.item != null ) {
			var ico = new h2d.Bitmap(game.items[a.item.getIndex()], spr);
			ico.colorKey = 0;
			ico.x = 5;
			ico.y = 5;
			px += 9;
		}
		var tf = new h2d.Text(game.font, spr);
		tf.text = a.text;
		tf.x = px;
		tf.y = 4;
		spr.x = 50 + (actions.length%3) * 100;
		spr.y = 50 + Std.int(actions.length/3) * 20;
		var int = new h2d.Interactive(spr.width, spr.height, spr);
		int.onOver = function(_) {
			if( a.enable() ) {
				spr.color.set(1.2, 1.2, 1.2);
				Res.sfx.menu.play();
			}
		};
		int.onOut = function(_) {
			spr.color.set(1,1,1);
		};
		int.onClick = function(_) {
			if( a.enable() ) {
				Res.sfx.confirm.play();
				actions = null;
				game.removeDialog();
				a.callb();
			}
		}
		int.cursor = Button;
		if( a.enable == null ) a.enable = function() return true;
		a.ui = { i : int, tf : tf };
		actions.push(a);
		return spr;
	}

	public function refresh() {
		if( actions == null ) return;
		for( a in actions ) {
			if( !a.enable() ) {
				a.ui.i.cursor = Default;
				a.ui.tf.textColor = 0x404040;
			} else {
				a.ui.i.cursor = Button;
				a.ui.tf.textColor = 0xFFFFFF;
			}
		}
	}

	public function click() {
		if( pending != null )
			return;
		game.removeDialog();
		dialog = new h2d.Sprite();
		actions = [];
		game.scene.add(dialog, 1);
		var dimg = new Dialog(50, 50, "", null);
		var index = kind.getIndex();
		var pt = Res.portraits.toTile();
		var p = new h2d.Anim(dimg);
		var px = (index >> 3) * 32;
		p.frames = [pt.sub(px, (index&7) * 16, 16, 16), pt.sub(px + 16, (index&7) * 16, 16, 16)];
		p.scale(2);
		p.x = 8;
		p.y = 10;
		p.speed = 10;
		dialog.addChild(dimg);
		var texts = getTexts();
		var sfx = Res.loader.load("sfx/speak0" + ((index + 1) % 5) + ".wav").toSound();
		var dtext = new Dialog(Const.W - 50, 50, texts[clickCount == 0 ? 0 : 1 + Std.random(hxd.Math.imin(Math.floor(Math.sqrt(clickCount)), texts.length - 1))], sfx);
		dialog.addChild(dtext);
		dtext.onReady = function() {
			p.speed = 0;
			p.currentFrame = 0;
			if( dialog != game.curDialog ) return;
			if( clickCount > 0 ) {
				for( a in getActions() )
					addAction(a);
				addAction( { item : null, text : "Exit", callb : function() game.removeDialog() } );
				refresh();
			}
		};
		dtext.onClick = function() {
			if( clickCount == 0 )
				click();
		};
		dtext.x = 50;
		clickCount++;
		game.curDialog = dialog;
	}

}