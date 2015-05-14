package managers
{
	import com.greensock.TweenLite;
	import com.greensock.TweenMax;
	import com.leebrimelow.starling.StarlingPool;
	import com.sticksports.nativeExtensions.flurry.Flurry;
	
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import core.Assets;
	import core.Constants;
	import core.Game;
	import core.SharedObjectUtils;
	import core.StageData;
	import core.Utils;
	
	import objects.AlertPopup;
	import objects.Booster;
	import objects.Coin;
	import objects.Fruit;
	import objects.Hurdle;
	import objects.LowerHero;
	import objects.ScoreData;
	import objects.StageCompletePopup;
	import objects.StageSelector;
	
	import stages.Play;
	
	import starling.core.Starling;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.extensions.PDParticleSystem;
	import starling.text.TextField;
	import starling.text.TextFieldAutoSize;
	import starling.textures.Texture;

	public class HurdleManager
	{
		private var play:Play;
		
		public var hurdles:Vector.<Hurdle> = new Vector.<Hurdle>;
		public var hurdlePools:Vector.<StarlingPool>;
		public var coins:Vector.<Coin> = new Vector.<Coin>;
		private var coinPool:StarlingPool;
		
		private var nextSpawnFrame:int;
		private var totalHurdleCount:int = 0;
		
		private var alertPopupTimer:uint;
		private var scoreDataList:Vector.<ScoreData>;
		
		private var textureIndex:int = -1;
		
		private const COIN_POOL_SIZE:int 		= 20;
		private const HURDLE_POOL_SIZE:int 		= 5;
		private const COIN_PERCENT:int 				= 10;
		private const BOOSTER_PERCENT:int           = 1;
//		private const HURDLE_HIDE_DURATION:int 		= 1000;		//ms
		
		public function HurdleManager(play:Play)
		{
			this.play = play;
			
			hurdlePools = new Vector.<StarlingPool>;
			
			updateHurdles();//Assets.getTexture(Assets.FIREBALL));
			coinPool = new StarlingPool(Coin, COIN_POOL_SIZE);
			
			nextSpawnFrame = 30;
			scoreDataList = ScoreData.data;
		}
		
		public function updateHurdles():void
		{
			textureIndex++;
			textureIndex = Math.min(textureIndex, play.stageData.hurdles.length - 1);
			
			var hurdlePool:StarlingPool = new StarlingPool(Hurdle, HURDLE_POOL_SIZE);
			for each(var hurdle:Hurdle in hurdlePool.items) {
				hurdle.setTexture(play.stageData.hurdles[textureIndex]);
			}
			hurdlePools.push(hurdlePool);
			
			// commented because this method is called only when hurdles is empty
			/*for each(hurdle in hurdles) {
				hurdle.setTexture(play.stageData.hurdles[textureIndex]);
			}*/
		}
		
		private var gapNum:int = 0;
		private var numFramesFromPrevHurdle:Number = 0;
		private var target:Image = null;
		private var targetSpawned:Boolean;
//		private var potionBoosterFrameCount:int;
		
		public function update():void {
			
			if(gapNum >= scoreDataList.length ) { //Stage complete
				updateHurdleAndCoin();
				if(play.isBoosterOn) {
					play.collisionManager.switchOffBooster();
				}
				if(numFramesFromPrevHurdle == 200 && Play.scoreHUD.getScore() == scoreDataList[scoreDataList.length-1].score) {
					spawnTarget();
				}
				if(targetSpawned) {
					play.updateHighScore();
					
					target.x -= StageData.hurdleSpeed *  Utils.scaleX * Play.speedFactor;
					if(target.x <= Game.screenWidth * 0.3) {
						unlockNewStage();
						play.pause();
						SoundManager.instance.play(SoundManager.APPLAUSE);
						setTimeout(addCompletePopup, 1000);
						Flurry.logEvent("Stage completed - "+ Play.stageId);
					}
				}
				return;
			}
			else {
				
				// init Gap
				
				if(Booster.isPotionBoosterOn) {
					if(numFramesFromPrevHurdle % 10 == 0) {
						spawnCoin();
					}
				}
				var longGap:Boolean = false;
				if(totalHurdleCount == scoreDataList[gapNum].score && play.isGap == false) {
					gapNum++;
					
					if(play.fromSelect && gapNum == 1)
						nextSpawnFrame += 70;
					
					if(gapNum != 1) {	// fix to remove initial gap
						if(scoreDataList[Play.progress+1].hurdleSpeedFactor != scoreDataList[Play.progress].hurdleSpeedFactor){
							nextSpawnFrame += 350;
							longGap = true;
//							GapManager.switchTween = false;
						}
						else
							nextSpawnFrame += 300;
					}
				}
				var speed:Number = Hurdle.speedInPixelPerFrame();
				if(numFramesFromPrevHurdle == nextSpawnFrame) {
					play.isGap = false;
					spawn();
					numFramesFromPrevHurdle = 0;
					
					var randomFactor:Number = play.stageData.randFactorHurdleDistance * (2 * Math.random() - 1 );
					randomFactor = 0;
					var val:int = Play.scoreData.baseDistance * (1 + randomFactor);
					nextSpawnFrame = (val * Utils.scaleX)/speed;
				}
				else if(play.isGap && !Booster.isPotionBoosterOn) {
					if(numFramesFromPrevHurdle % int(13 * Play.scoreData.timeFactor) == 0 && numFramesFromPrevHurdle <= (nextSpawnFrame - 30)) {
						spawnCoin();
					}
				}
			}
	
			updateHurdleAndCoin();
		}
		
		private function addCompletePopup():void
		{
			var stageCompletePopup:StageCompletePopup= new StageCompletePopup(play);
			PopupManager.display(stageCompletePopup);
			
		}
		
		private function updateHurdleAndCoin():void
		{
			var hurdleSpeed:Number = Hurdle.speedInPixelPerFrame();
			
			for(var i:int = hurdles.length -1; i >= 0; i--)
			{
				var hurdle:Hurdle = hurdles[i];
				if(!Play.isPhysics) {
					hurdle.x -= hurdleSpeed;
				}
				
				if(hurdle.display && hurdle.hasCrossed == false && hurdle.x <= (play.lowerHero.x - hurdle.width) ) {
					hurdle.hasCrossed = true;
//					hurdle.disableCollision();
					
					if(!play.collisionManager.ignoreThisScore) {	// TUTORIAL: ignore heroHurt for tutorial score
						Play.scoreHUD.addScore(1);
						//check quests
						if(SharedObjectUtils.isQuestsUnlocked()) {
							var reward:int = Quest.instance.checkAndNotify();
							if(reward > 0)
								notifyQuestComplete(reward);
						}
					}
					play.collisionManager.ignoreThisScore = false;
					
					for(var l:int = 1; l < scoreDataList.length; l++) {
						if(Play.scoreHUD.getScore() == scoreDataList[l].score) {
							play.isGap = true;
							break;
						}
					}
					
				}
				
				var xCheck:Number = hurdle.x + hurdle.width;
				if(xCheck < 0) {
					destroyHurdle(hurdle);
				}else if(xCheck < LowerHero.Xo){
					hurdle.disableCollision();
				}else if(hurdle.x < LowerHero.Xo + play.lowerHero.width + 250 * Utils.scaleX) {
					hurdle.enableCollision();
					if(play.isBoosterOn && play.boosterType == Booster.UMBRELLA && hurdle.isTop){
						hurdle.disableCollision();
						if(!hurdle.isFlown) {
							hurdle.flyOff();
							hurdle.isFlown = true;
						}
					} else if(play.isBoosterOn && play.boosterType == Booster.MISSILE && !hurdle.isTop){
						hurdle.disableCollision();
						if(!hurdle.isFallen) {
							hurdle.fallOff();
							hurdle.isFallen = true; 
						}
					}
				}
			}
			
			for(i = coins.length - 1; i >= 0; i--)
			{
				var coin:Coin = coins[i];
				if(!Play.isPhysics) {
					coin.x -= hurdleSpeed;
				}
				
				xCheck = coin.x + coin.width;
				if(xCheck < 0) {
					destroyCoin(coin);
				}else if(xCheck < LowerHero.Xo){
					coin.disableCollision();
				}else if(coin.x < LowerHero.Xo + play.lowerHero.width + 50 * Utils.scaleX) {
					coin.enableCollision();
				}
			}
			
			if(fruit) {
				xCheck = fruit.x + fruit.width;
				if(xCheck < 0) {
					destroyFruit();
				}else if(xCheck < LowerHero.Xo){
					fruit.disableCollision();
				}else if(fruit.x < LowerHero.Xo + play.lowerHero.width + 50 * Utils.scaleX) {
					fruit.enableCollision();
				}
			}
			
			if(booster) {
				xCheck = booster.x + booster.width;
				if(xCheck < 0) {
					destroyBooster();
				}else if(xCheck < LowerHero.Xo){
					booster.disableCollision();
				}else if(booster.x < LowerHero.Xo + play.lowerHero.width + 50 * Utils.scaleX) {
					booster.enableCollision();
				}
			}
			numFramesFromPrevHurdle++;
		}
		private var sparkle:PDParticleSystem;
		private var qcSprite:Sprite = new Sprite();
		private function notifyQuestComplete(reward:int):void {
			SoundManager.instance.play("chime");
			qcSprite = new Sprite();
			
			sparkle = new PDParticleSystem(XML(new Assets.effectXML()),Assets.getTexture(Assets.EFFECT_PARTICLE));
			Starling.juggler.add(sparkle);
			qcSprite.addChild(sparkle);
			sparkle.start(2);
			sparkle.touchable = false;
			
			var qcBG:Image = new Image(Assets.getTexture(Assets.YELLOW_BG));
			qcBG.height = 100 * Utils.scaleY;
			qcBG.width =300 * Utils.scaleX;
			qcSprite.addChild(qcBG);
			var questCompleted:TextField = new TextField(qcBG.width,qcBG.height,"Completed a Quest \n Claim your " + reward + " coins!",Constants.FONT,36 * Utils.scale);
			qcSprite.addChild(questCompleted);
			Utils.centerXandYToParent(questCompleted);
			Utils.centerXandYToParent(sparkle);
			
			play.addChild(qcSprite);
			Utils.centerXToParent(qcSprite);
			qcSprite.y = 100 * Utils.scaleY;
			TweenMax.delayedCall(2,fadeQuestHUD);
		}
		
		private function fadeQuestHUD():void {
			if(qcSprite)
				TweenMax.to(qcSprite, 0.5, {alpha:0, onComplete:destroyQuestHUD});
		}
		
		private function destroyQuestHUD():void
		{
			TweenMax.killTweensOf(qcSprite);
			if(qcSprite) {
				qcSprite.removeFromParent(true);
				qcSprite = null;
			}
			if(sparkle) {
				sparkle.removeFromParent(true);
				sparkle = null;
			}
		}
		
		private function spawnTarget():void
		{
			targetSpawned = true;
			target = new Image(Assets.getTexture(play.stageData.targetAsset));
			target.height = play.stageData.targetHeight;
			target.width = play.stageData.targetWidth;
			target.y = play.stageData.floorY  * Utils.scaleY - target.height;
			target.x = Game.screenWidth;
			play.addChild(target);
			
		}
		
		private function addAlert(texture:Texture):void {
			play.pause();
			var alertPopup:AlertPopup = new AlertPopup(play, texture);
			PopupManager.display(alertPopup);
		}
		
		public function destroyCoin(coin:Coin):void {
			for(var i:int = 0; i<coins.length; i++)
			{
				if(coin == coins[i])
				{
					coins.splice(i, 1);
					coinPool.returnObject(coin);
					
					coin.display.removeFromParent(true);
					coin.isCollided = true;
//					coin.hasCrossed = false;
					coin.disableCollision();
					if(coin.body)
						coin.body.space = null;
				}
			}
			
		}
		
		public function destroyFruit():void {
			if(fruit) {
				fruit.display.removeFromParent(true);
				fruit.isCollided = true;
				//					coin.hasCrossed = false;
				fruit.disableCollision();
				if(fruit.body)
					fruit.body.space = null;
				fruit.dispose();
				fruit = null;
			}
		}
		
		public function destroyBooster():void {
			if(booster) {
				booster.display.removeFromParent(true);
				booster.isCollided = true;
				//					coin.hasCrossed = false;
				booster.disableCollision();
				if(booster.body)
					booster.body.space = null;
				booster.dispose();
				booster = null;
			}
		}
		
		
		private function destroyHurdle(hurdle:Hurdle):void
		{
			for(var i:int = 0; i<hurdles.length;i++)
			{
				if(hurdle == hurdles[i])
				{
					hurdles.splice(i,1);
					hurdle.owner.returnObject(hurdle);

					hurdle.stopAnimation(0);
					hurdle.display.removeFromParent(true);
					hurdle.isCollided = true;
					hurdle.hasCrossed = false;
					hurdle.body.space = null;
					hurdle.disableCollision();
				}
			}
			
		}
		
		private function spawn():void
		{
			var random:int = int(Math.random() * 100);
			if(random <= COIN_PERCENT && !Play.isTutorial) {
				spawnCoin();
				return;
			}
			
			if(random <= (COIN_PERCENT * 3) && Quest.currentFruitChallenge && 
				(Quest.currentFruitChallenge.stageId == Play.stageId) && !Play.isTutorial)
				spawnFruit();
			
			if(random >= (100 - BOOSTER_PERCENT * 1) && !Play.isTutorial && 
				!play.isBoosterOn && SharedObjectUtils.isBoostersUnlocked())
				spawnBooster();
			
			var poolIndex:int = int(Math.random() * hurdlePools.length);
			var hurdlePool:StarlingPool = hurdlePools[poolIndex];
			
			var hurdle:Hurdle = hurdlePool.getObject() as Hurdle;
			hurdle.alpha = 1;
			hurdle.isCollided = false;
			hurdle.isFlown = false;
			hurdle.isFallen = false;
			hurdle.disableCollisionForBooster = false;
			hurdle.disableCollision();
			hurdle.owner = hurdlePool;
			hurdle.body.space = Play.space;
			
			var hurdleSpeed:Number = Hurdle.speedInPixelPerFrame() * Game.FPS;
			var randomFactor:Number = Play.scoreData.randFactorHurdleSpeed * (2 * Math.random() - 1 );
			hurdle.body.velocity.length = hurdleSpeed * (1 + randomFactor);
			
			hurdles.push(hurdle);
			hurdle.x = Game.screenWidth;
			
			var isTop:Boolean = random % 2 == 0;
			if(Play.isTutorial) {
				isTop = TutorialHelper.tutorialTaskStatus == 0 ? false : true;
			}
			
			if(isTop) {
				hurdle.y = hurdle.hurdleMeta.topY * Utils.scaleY;	//play.stageData.hurdleHeightHigh * Utils.scaleY;
				hurdle.isTop = true;
			}else {
				hurdle.y = hurdle.hurdleMeta.downY * Utils.scaleY;	//play.stageData.hurdleHeightLow * Utils.scaleY;
				hurdle.isTop = false;
			}
			//question_mark
			if(100 * Math.random() < Play.scoreData.hideHurdlePercent) {
				hurdle.hide(isTop);
				setTimeout(hurdle.show, play.stageData.hurdleHideDuration * Play.timeFactor);
			}
			
			play.addChild(hurdle.display);
			hurdle.startAnimation();
			totalHurdleCount ++;
		}
		private var booster:Booster = null;
		private function spawnBooster():void
		{
			if(!booster) {
				var rand:int = int(Math.random() * Booster.boosterList.length);
				
				booster = new Booster(Booster.boosterList[rand]);
				booster.isCollided = false;
				booster.disableCollision();
				if(booster.body)
					booster.body.space = Play.space;
				booster.alpha = 1;
				
				booster.y = play.stageData.coinHeight * 0.7 * Utils.scaleY;
				booster.x = Game.screenWidth;
				play.addChild(booster.display);
			}
			
		}
		
		private var fruit:Fruit = null;
		private function spawnFruit():void
		{
			if(!fruit) {
				var fruitName:String = getFruit();
				fruit = new Fruit(fruitName);
				fruit.isCollided = false;
				fruit.disableCollision();
				//			coin.hasCrossed = false;
				//			coin.body.cbTypes.add(Play.hurdleCollisionType);
				if(fruit.body)
					fruit.body.space = Play.space;
				fruit.alpha = 1;
				
	//			coins.push(letter);
				if(Play.stageId == StageData.ID_SEA) {
					var rand:int = Math.random() * 2;
					if(rand == 0)
						fruit.y = play.stageData.hurdleHeightHigh *  Utils.scaleY;
					else
						fruit.y = play.stageData.hurdleHeightLow *  Utils.scaleY;
				}
				else {
					fruit.y = play.stageData.coinHeight *  Utils.scaleY;
				}
				fruit.x = Game.screenWidth;
				play.addChild(fruit.display);
			}
		}
		
		private function getFruit():String
		{
			var obj:Object = Quest.currentFruitChallenge._obj;
			var random:int = int(Math.random() * Utils.objectLength(obj));
			var str:String = Utils.getKeyAt(random, obj);
			return str;
		}
		
		private function spawnCoin():void {
			var coin:Coin = coinPool.getObject() as Coin;
			coin.isCollided = false;
			coin.disableCollision();
			if(coin.body)
				coin.body.space = Play.space;
			coin.alpha = 1;
			
			coins.push(coin);
			if(Booster.isPotionBoosterOn) {
				if(play.upperHero) {
					coin.y = play.upperHero.y + 50 * Utils.scaleY;
				} else {
					coin.y = play.lowerHero.y + 10 * Utils.scaleY;
				}
			} else {
				
				if(Play.stageId == StageData.ID_SEA) {
					var rand:int = Math.random() * 2;
					if(rand == 0)
						coin.y = play.stageData.hurdleHeightHigh *  Utils.scaleY;
					else
						coin.y = play.stageData.hurdleHeightLow *  Utils.scaleY;
				}
				else {
					coin.y = play.stageData.coinHeight *  Utils.scaleY;
				}
			}
			coin.x = Game.screenWidth;
			play.addChild(coin.display);
		}
		
		public function destroy():void {
			clearTimeout(alertPopupTimer);
			destroyQuestHUD();
			coinPool.destroy();
			coinPool = null;
			if(coins) {
				for each(var coin:Coin in  coins) {
					coin.dispose();
					coin = null;
				}
				coins.length = 0;
				coins = null;
			}
			
			if(hurdlePools) {
				for each(var hurdlePool:StarlingPool in hurdlePools) {
					hurdlePool.destroy();
					hurdlePool = null;
				}
				hurdlePools.length = 0;
				hurdlePools = null;
			}
			
			if(hurdles) {
				for each(var hurdle:Hurdle in hurdles) {
					hurdle.dispose();
					hurdle = null;
				}
				hurdles.length = 0;
				hurdles = null;
			}
		}
		
		
		public static var _newStageUnlocked:Boolean = false;
		private function unlockNewStage():void
		{
			var stageOrder:Array = StageData.order;
			for(var i:int; i < stageOrder.length; i++) {
				if(SharedObjectUtils.getStageState(stageOrder[i]) == -1) {
					SharedObjectUtils.setStageState(stageOrder[i], 1);
					_newStageUnlocked = true;
					break;
				}
			}
			SharedObjectUtils.setStageState(Play.stageId, 2);	
		}
		
	}
}