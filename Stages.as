package core
{
	import flash.utils.Dictionary;
	
	import objects.LowerHero;
	import objects.ScoreData;
	import objects.UpperHero;
	
	import stages.Play;

	public class Stages
	{
		private static var _instance:Stages;
		
		public var stageList:Vector.<StageData>;
		public var stageDict:Dictionary;	// id => StageData
		
		public function Stages(singletonEnforcer:SingletonEnforcer) {
		}
		
		public static function get instance(): Stages {
			if(_instance == null) {
				_instance = new Stages(new SingletonEnforcer());
			}
			return _instance;
		}
		
		public function initialize():void {
			stageList = new Vector.<StageData>;
			stageList.push(
				initStage1(),
				initStage2(),
				initStage3(),
				initStage4()
			);
			
			stageDict = new Dictionary();
			for(var i:int; i < stageList.length; i++) {
				var stage:StageData = stageList[i];
				stageDict[stage.id] = stage;
			}
		}
		
		private function initStage1():StageData {
			ScoreData.scoreDataVectorList.push(ScoreData.beach);
			
			var stageData:StageData = new StageData();
			stageData.id = StageData.ID_BEACH;
			stageData.name = StageData.NAME_BEACH;
			stageData.previewAsset  = Assets.SELECTION_BEACH;
			stageData.difficulty = StageData.DIFF_DIFF;
			stageData.unlockGoldRequired = 8000;
			
			stageData.heroName = "Abie";
			stageData.heroGender = "";

			stageData.heroAsset = Assets.SEAL + "_def_1";
			stageData.lowerHero = Assets.SEAL;//LowerHero.SEAL;
			stageData.upperHero = Assets.GIFT;
			stageData.primaryAction = Play.UPPER_HERO_JUMP;
			stageData.secondaryAction = Play.BOTH_HERO_JUMP;
			stageData.tutorialText = "Help " + stageData.heroName + " meet his soulmate!";
			
			stageData.targetAsset = Assets.SEAL_TARGET;
			stageData.targetHeight = 105 * Utils.scaleY;
			stageData.targetWidth = 105 * Utils.scaleX;
			stageData.targetName = "Suzie";
			
			//			stageData.floorY = 500;
			stageData.floorY  			-= 40;
			stageData.hurdles.push(HurdleMeta.BUCKET, HurdleMeta.CRAB, HurdleMeta.TORTOISE);
			stageData.hurdleHeightLow = HurdleMeta.BUCKET.downY;
			stageData.hurdleHeightHigh = HurdleMeta.BUCKET.topY;
			//			stageData.coinHeight 		+= 10;
			stageData.height = 127;
			stageData.primActionTime 	= 0.68;
			stageData.secActionTime 	= 0.7;
			
			stageList.push(stageData);
			return stageData;
		}
		
		private function initStage2():StageData {
			ScoreData.scoreDataVectorList.push(ScoreData.jungle);
			
			var stageData:StageData = new StageData();
			stageData.id = StageData.ID_JUNGLE;
			stageData.name = StageData.NAME_JUNGLE;
			stageData.previewAsset  = Assets.SELECTION_JUNGLE;
			stageData.difficulty = StageData.DIFF_EASY;
			stageData.unlockGoldRequired = 0;
			
			stageData.heroName = "Jango";
			stageData.heroGender = "his";

			stageData.heroAsset = Assets.MONKEY + "_def_1";
			stageData.lowerHero = LowerHero.SKATE;
			stageData.upperHero = UpperHero.MONKEY;
			stageData.primaryAction = Play.UPPER_HERO_JUMP;
			stageData.secondaryAction = Play.BOTH_HERO_JUMP;
			stageData.tutorialText = "Help " + stageData.heroName + " reach his parents!";
			
			stageData.targetAsset = Assets.JUNGLE_TARGET;
			stageData.targetHeight = 200 * Utils.scaleY;
			stageData.targetWidth = 230 * Utils.scaleX;
			stageData.targetName = "Parents";
			
			stageData.floorY  			-= 70;
			stageData.coinHeight 		-= 10;
			stageData.height = 130;
			stageData.primActionTime 	= 0.85;	//0.75 release1.0;
			stageData.secActionTime 	= 0.75;	//0.65;
			
			stageData.hurdles.push(HurdleMeta.BOULDER, HurdleMeta.LADY_BUG, HurdleMeta.DEVIL);
			stageData.hurdleHeightLow = HurdleMeta.BOULDER.downY;
			stageData.hurdleHeightHigh = HurdleMeta.BOULDER.topY;
			
			stageList.push(stageData);
			return stageData;
		}
		
		private function initStage3():StageData {
			ScoreData.scoreDataVectorList.push(ScoreData.scary);
			
			var stageData:StageData = new StageData();
			stageData.id = StageData.ID_SCARY;
			stageData.name = StageData.NAME_SCARY;
			stageData.previewAsset  = Assets.SELECTION_SCARY;
			stageData.difficulty = StageData.DIFF_MEDIUM;
			stageData.unlockGoldRequired = 1000;
			
			stageData.heroName = "Gogo";
			stageData.heroGender = "her";

			stageData.heroAsset = Assets.SHEEP_FULL;
			stageData.lowerHero = Assets.SHEEP_BODY;//LowerHero.SHEEP_BODY;
			stageData.upperHero = Assets.SHEEP_HEAD;//UpperHero.SHEEP_HEAD;
			stageData.primaryAction = Play.UPPER_HERO_DUCK;
			stageData.secondaryAction = Play.BOTH_HERO_JUMP;
			stageData.tutorialText = "Help " + stageData.heroName + " reach her farmland!";
			
			stageData.targetAsset = Assets.SCARY_TARGET;
			stageData.targetHeight = 200 * Utils.scaleY;
			stageData.targetWidth = 400 * Utils.scaleX;
			stageData.targetName = "Family";
			
			//			stageData.floorY = 500;
			stageData.floorY  			-= 40;
			stageData.coinHeight 		+= 20;
			
			stageData.primActionTime 	= 0.75;	
			stageData.secActionTime 	= 0.75;	
			
			stageData.hurdles.push(HurdleMeta.SKULL, HurdleMeta.PUMPKIN, HurdleMeta.GHOST);
			stageData.hurdleHeightLow = HurdleMeta.SKULL.downY;
			stageData.hurdleHeightHigh = HurdleMeta.SKULL.topY;
			
			stageList.push(stageData);
			return stageData;
		}
		
		private function initStage4():StageData {
			ScoreData.scoreDataVectorList.push(ScoreData.jungle);
			
			var stageData:StageData = new StageData();
			stageData.id = StageData.ID_SEA;
			stageData.name = StageData.NAME_SEA;
			stageData.previewAsset  = Assets.SELECTION_SEA;
			stageData.difficulty = StageData.DIFF_MEDIUM;
			stageData.unlockGoldRequired = 4000;
			
			stageData.heroName = "Tazo";
			stageData.heroGender = "his";
			stageData.heroAsset = Assets.TURTLE + "_def_1";
			stageData.lowerHero = LowerHero.TURTLE;
			stageData.primaryAction = Play.LOWER_HERO_DIVE_DOWN;
			stageData.secondaryAction = Play.LOWER_HERO_DIVE_UP;
			stageData.tutorialText = "Help " + stageData.heroName + " reach his Grand Pa!";
			
			stageData.targetAsset = Assets.SEA_TARGET;
			stageData.targetHeight = 200 * Utils.scaleY;
			stageData.targetWidth = 230 * Utils.scaleX;
			stageData.targetName = "Grand Pa";
			
			stageData.floorY  			-= 130;
			stageData.coinHeight 		+= 10;
			stageData.height = 100;
			stageData.primActionTime 	= 0.8;
			stageData.secActionTime 	= 0.8;
			
			stageData.hurdles.push(HurdleMeta.SEA_1,HurdleMeta.SEA_2, HurdleMeta.SEA_3);
			stageData.hurdleHeightLow = HurdleMeta.SEA_1.downY;
			stageData.hurdleHeightHigh = HurdleMeta.SEA_1.topY;
			stageData.hurdleHideDuration = 1150; //ms
			stageList.push(stageData);
			return stageData;
		}
	}
}

internal class SingletonEnforcer {}