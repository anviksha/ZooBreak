package objects
{
	import com.greensock.TweenMax;
	import com.leebrimelow.starling.StarlingPool;
	
	import nape.phys.Body;
	
	import stages.Play;
	
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.MovieClip;
	import starling.display.Sprite;
	import starling.textures.Texture;

	public class PhysicsBody
	{
		public var owner:StarlingPool;
		public var body:Body;
		protected var _display:Sprite;
		public var _mc:MovieClip;

		public function PhysicsBody(texture:Texture = null)
		{
			createDisplay(texture);
			if(Play.isPhysics) {
				createBody();
			}
		}
		
		protected function createDisplay(texture:Texture):DisplayObject {
			return null;
		}
		
		protected function createBody():Body {
			return null;
		}
		
		protected function get initialX():Number {
			return 0;
		}
		
		protected function get initialY():Number {
			return 0;
		}
		
		public function get display():Sprite {
			return _display;
		}
		
		public function get x():Number {
			if(body){	// && !isNaN(body.position.x)) {
				return body.position.x;
			}
			return display.x;
		}
		
		public function get y():Number {
			if(body){	// && !isNaN(body.position.y)) {
				return body.position.y;
			}
			return display.y;
		}
		
		public function set x(val:Number):void {
			if(body) {
				body.position.x = val;
			}
			/*else */if(display) {		// coin flickering fix. else was for sheep?
				display.x = val;
			}
		}
		
		public function set y(val:Number):void {
			if(body) {
				body.position.y = val;
			}
			/*else */if(display) {		// coin flickering fix
				display.y = val;
			}
		}
		
		public function get width():Number {
			return display.width;
		}
		
		public function get height():Number {
			return display.height;
		}
		
		public function set width(val:Number):void {
			display.width = val;
		}
		
		public function set height(val:Number):void {
			display.height = val;
		}
		
		public function dispose():void {
			TweenMax.killTweensOf(this);
			TweenMax.killTweensOf(display);
			
			if(body) {
				if(body.userData) {
					body.userData.object = null;
				}
				body.space = null;//.bodies.remove(body);
				body = null;
			}
			if(display) {
				display.removeChildren(0, -1, true);
				display.removeFromParent(true);
				_display = null;
			}
		}
		
		public function get alpha():Number {
			return display.alpha;
		}
		
		public function set alpha(val:Number):void {
			if(display)
				display.alpha = val;
		}
		
		public function stopAnimation(frame:int):void {
			if(_mc) {
				Starling.juggler.remove(_mc);
				_mc.stop();
				_mc.currentFrame = frame;
			}
		}
		
		public function startAnimation():void {
			if(_mc) {
				Starling.juggler.add(_mc);
				_mc.play();
			}
		}
	}
}