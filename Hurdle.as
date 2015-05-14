package objects
{
	import com.greensock.TweenMax;
	import com.greensock.easing.Linear;
	import com.greensock.easing.Quad;
	
	import core.Assets;
	import core.Game;
	import core.HurdleMeta;
	import core.StageData;
	import core.Utils;
	
	import managers.SoundManager;
	
	import nape.geom.Vec2;
	import nape.phys.Body;
	import nape.phys.BodyType;
	import nape.shape.Polygon;
	
	import stages.Play;
	
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.MovieClip;
	import starling.display.Sprite;
	import starling.textures.Texture;

	public class Hurdle extends PhysicsBody
	{
		private var img:Image;
		public var hasCrossed:Boolean;
		public var hurdleMeta:HurdleMeta;
		public var isCollided:Boolean;
		public var isTop:Boolean;
		public var isFlown:Boolean;
		public var isFallen:Boolean;
		public var disableCollisionForBooster:Boolean;
		
		public function Hurdle()
		{
			hasCrossed = false;
		}
		
		private function get movieclip():MovieClip {
			var v:Vector.<Texture> = Assets.getTextures(hurdleMeta.name);
			return new MovieClip(v, 8);
		}
		
		public function setTexture(hurdleMeta:HurdleMeta):void {
			this.hurdleMeta = hurdleMeta;
			
			if(display) {
				display.removeFromParent(true);
				//display = null;
			}
			if(body) {
				//body.userData.graphic = null;
				body.space = null;
				body = null;
			}
			
			createDisplay(null);
			createBody();
//			_mc.play();
		}
		
		private var hidingSprite:Sprite;
		
		public function hide(isTop:Boolean):void {
			hidingSprite = new Sprite();
			
			var bgSprite:Sprite = new Sprite();
			var bg:MovieClip = getDuplicateMovieClip();
			bgSprite.addChild(bg);
			hidingSprite.addChild(bgSprite);
			
			display.addChild(hidingSprite);
			
			if(!isTop) {
				hidingSprite.y -= (hurdleMeta.downY - hurdleMeta.topY) * Utils.scaleY;	// / display.scaleY;//hidingSprite.height - hurdleHeight;
			} else {
				hidingSprite.y += (hurdleMeta.downY - hurdleMeta.topY) * Utils.scaleY;
			}
			Utils.centerXToSibling(hidingSprite, _mc);
			
			TweenMax.to(hidingSprite,0.08,{alpha:0.3,yoyo:true,repeat:5});
			TweenMax.to(display,0.08,{alpha:0.3,yoyo:true,repeat:5});
		}
		
		public function show():void {
			if(hidingSprite) {
				TweenMax.to(hidingSprite, 0.2, {x: Game.screenWidth, onComplete:destroy, ease:Linear.easeNone});
			}
			function destroy():void {
				hidingSprite.removeChildren(0, -1, true);
				hidingSprite.removeFromParent(true);
				hidingSprite = null;
			}
		}
		
		private var pseudoHurdle:Sprite;
		public function flyOff():void {
			SoundManager.instance.play(SoundManager.WOOSH);
			var bg:MovieClip = getDuplicateMovieClip();
			pseudoHurdle = new Sprite();
			pseudoHurdle.addChild(bg);
			display.alpha = 0;
			disableCollisionForBooster = true;
			var play:Sprite = display.parent as Sprite;
			play.addChild(pseudoHurdle);
			Utils.centerXandYToSibling(pseudoHurdle, display);
			TweenMax.to(pseudoHurdle,0.25,{y:100 *Utils.scaleY, onComplete:completeYTween,ease:Quad.easeOut});
			TweenMax.to(pseudoHurdle,0.6,{x:-1.5*pseudoHurdle.width, onComplete:destroyPseudo});
		}
		
		public function fallOff():void {
			SoundManager.instance.play("woosh_1");
			var bg:MovieClip = getDuplicateMovieClip();
			pseudoHurdle = new Sprite();
			pseudoHurdle.addChild(bg);
			display.alpha = 0;
			disableCollisionForBooster = true;
			
			var play:Sprite = display.parent as Sprite;
			play.addChild(pseudoHurdle);
			Utils.centerXandYToSibling(pseudoHurdle, display);
			TweenMax.to(pseudoHurdle,0.15,{y:300 *Utils.scaleY,onComplete:completeFallYTween,ease:Quad.easeOut});
			TweenMax.to(pseudoHurdle,0.6,{x:Game.screenWidth * 0.8, onComplete:destroyPseudo});
		}
		
		private function getDuplicateMovieClip():MovieClip {
			var bg:MovieClip = movieclip;
			bg.height = hurdleMeta.height * Utils.scaleY;
			bg.width = hurdleMeta.width * Utils.scaleX;
			bg.pivotX = (1 - hurdleMeta.bodyRatio) * 0.5 * movieclip.width;
			bg.pivotY = (1 - hurdleMeta.bodyRatio) * 0.5 * movieclip.height;
			return bg;
		}
		
		private function completeYTween():void {
			TweenMax.to(pseudoHurdle,0.25,{y:300 *Utils.scaleY,ease:Quad.easeIn});
			
		}
		private function completeFallYTween():void {
			TweenMax.to(pseudoHurdle,0.15,{y:Game.screenHeight, ease:Quad.easeIn});
			
		}
		
		private function destroyPseudo():void {
			if(pseudoHurdle) {
				pseudoHurdle.removeFromParent(true);
				pseudoHurdle = null;
			}
		}
		
		override protected function createDisplay(texture_:Texture):DisplayObject {
			if(hurdleMeta) {
				_display = new Sprite();
				_mc = movieclip;
				_display.addChild(_mc);
				_mc.height = hurdleMeta.height * Utils.scaleY;
				_mc.width = hurdleMeta.width * Utils.scaleX;
				_mc.pivotX = (1 - hurdleMeta.bodyRatio) * 0.5 * movieclip.width;
				_mc.pivotY = (1 - hurdleMeta.bodyRatio) * 0.5 * movieclip.height;
				
				display.touchable = false;
			}
			return _display;
		}
		
		override protected function createBody():Body {
			if(!display) 	return null;
			
			body = new Body(BodyType.KINEMATIC, new Vec2(display.x, display.y));
			
			var polygon:Polygon = new Polygon(Polygon.rect(0, 0, width * hurdleMeta.bodyRatio, height * hurdleMeta.bodyRatio));
			polygon.material.elasticity = 0;
			polygon.material.density = 1;
			polygon.material.staticFriction = 0;
			polygon.sensorEnabled = true;
			
			body.shapes.add(polygon);
			body.velocity = Vec2.get(-speedInPixelPerFrame() * Game.FPS, 0);
			body.userData.graphic = display;
			body.userData.object = this;
			
			return body;
		}
		
		public static function speedInPixelPerFrame():Number {
			var speed:Number = StageData.hurdleSpeed * Play.scoreData.hurdleSpeedFactor * Utils.scaleX;
			return speed;	// * (60 / Game.FPS);
		}
		
		public function disableCollision():void {
			if(body) {
				body.cbTypes.clear();
			}
		}
		
		public function enableCollision():void {
			if(disableCollisionForBooster)
				return;
			if(body) {
				body.cbTypes.add(Play.hurdleCollisionType);
			}
		}
		
		override public function dispose():void {
			if(hidingSprite) {
				TweenMax.killTweensOf(hidingSprite);
				hidingSprite.dispose();
				hidingSprite = null;
			}
			if(_display) {
				TweenMax.killTweensOf(_display);
			}
			if(pseudoHurdle) {
				TweenMax.killTweensOf(pseudoHurdle);
				pseudoHurdle.dispose();
				pseudoHurdle = null;
			}
			super.dispose();
		}
	}
}