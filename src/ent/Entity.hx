package ent;

class Entity {
	
	public var id : Int;
	public var x(get,never) : Float;
	public var y(get,never) : Float;
	public var mc : h2d.Anim;
	var gravity : Float = 0.2;
	var frictX = 0.85;
	var frictY = 0.94;
	var bw : Int;
	var bh : Int;
	
	var cw = 16;
	var ch = 16;
	
	var fight : Fight;
	
	public var life : Float = 0.;
	
	// using deepnight tuto :-)
	public var cx			: Int;
	public var cy			: Int;
	public var xr			: Float;
	public var yr			: Float;
	
	public var dx			: Float;
	public var dy			: Float;

	
	public function new(id,x,y) {
		this.id = id;
		fight = Fight.inst;
		mc = new h2d.Anim(fight.sprites);
		mc.colorAdd = new h3d.Vector(0, 0, 0, 0);
		bw = 4;
		bh = 16;
		
		//mc.addChild(new h2d.Bitmap(h2d.Tile.fromColor(0xFFFFFFFF)));
		setPos(x, y);

		mc.colorKey = 0x333333;
		mc.speed = 12;
		playAnim(id);
		fight.entities.push(this);
		init();
		update(0);
	}
	
	function colWith( e : Entity ) {
		return Math.abs(x - e.x) < (cw + e.cw) / 32 && Math.abs( e.y - y ) < (ch + e.ch) / 32;
	}
	
	public function hit( power : Float ) {
		mc.colorAdd.set(1, -0.5, -0.5, 0);
		life -= power;
		if( life <= 0 ) {
			life = 0;
			kill();
		}
	}

	function kill() {
		life = 0;
		remove();
	}
	
	function init() {
	}
	
	public function setPos(x, y) {
		cx = Std.int(x);
		cy = Std.int(y);
		xr = x - cx;
		yr = y - cy;
		dx = dy = 0;
	}

	public function remove() {
		mc.remove();
		fight.entities.remove(this);
	}
	
	function onCollide(col:Fight.Collide) {
		if( col == Lava ) {
			new Fx(7, x, y);
			kill();
		}
		return true;
	}
	
	function collide(cx, cy) {
		return cx < 0 || cy < 0 || cx >= fight.width || cy >= fight.height || switch( fight.col[cx][cy] ) {
		case No: false;
		case Lava: if( y > cy ) onCollide(Lava) else false;
		case col: onCollide(col);
		}
	}
	
	inline function get_x() {
		return cx + xr;
	}
	
	inline function get_y() {
		return cy + yr;
	}
	
	function playAnim(id) {
		var a = fight.anims[id];
		if( a == null ) throw "Missing anim " + id;
		mc.frames = a;
		mc.currentFrame = 0;
	}

	public function update(dt:Float) {
		xr += dx*dt/16;
		dx *= Math.pow(frictX,dt);
		if( collide(cx-1,cy) && xr<=0.3 ) {
			dx = 0;
			xr = 0.3;
		}
		if( collide(cx+1,cy) && xr>=0.7 ) {
			dx = 0;
			xr = 0.7;
		}
		while( xr<0 ) {
			cx--;
			xr++;
		}
		while( xr>1 ) {
			cx++;
			xr--;
		}
		
		var ca = mc.colorAdd;
		ca.x *= 0.5;
		ca.y *= 0.5;
		ca.z *= 0.5;

		dy += gravity * dt;
		yr += dy*dt/16;
		dy *= Math.pow(frictY, dt);
		
		if( collide(cx, cy-1) && yr <= ch / 32 ) {
			if( dy < 0 ) dy = -0.01;
			yr = ch/32;
		}
		if( collide(cx,cy+1) && yr >= 1 - ch/32 ) {
			dy = 0;
			yr = 1 - ch/32;
		}
		while( yr<0 ) {
			cy--;
			yr++;
		}
		while( yr>1 ) {
			cy++;
			yr--;
		}

		mc.x = Std.int(x*16);
		mc.y = Std.int(y*16 + (ch>>1) + 1);
	}
	
}