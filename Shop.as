package managers 
{
	import flash.utils.Dictionary;
	
	import core.SharedObjectUtils;
	import core.StageData;
	
	import objects.ShopItem;

	public class Shop 
	{
		private static var _instance:Shop;
		
		private var itemList:Vector.<ShopItem>;
		private var itemDict:Dictionary;	// id => ShopItem
		
		// items
		public static const SKATE_BLUE:String = "blue-skate";
		public static const HAT_BLUE:String = "blue-hat";
		public static const RED_CAP:String = "red-cap";
		public static const RED_SKATE:String = "red-skate";
		
		public static const CHAIN_GOLD:String = "tag";
		public static const TATTOO_1:String = "tattoo";
		public static const RED_GIFT:String = "red-gift";
		
		public static const SHOE_PINK:String = "pink-shoe";
		public static const MUFFLER_PINK:String = "pink-muffler";
		public static const EAR_PLUG:String = "ear-plug";
		
		public static const GOGGS:String = "goggs";
		public static const EYE_MASK:String = "eye-mask";
		public static const DAGGER:String = "dagger";
		
		// status
		public static const STATUS_NO:int = 1;			// no
		public static const STATUS_OWN:int = 2;			// own
		public static const STATUS_USE:int = 3;			// use
		
		// category: only one item usable per category
		public static const CAT_NONE:int			= 99;
		public static const CAT_MONKEY_CAP:int 		= 1;
		public static const CAT_SKATE:int 			= 2;
		
		public static const CAT_SHEEP_MUFFLER:int	= 3;
		public static const CAT_SHEEP_SHOE:int		= 4;
		public static const CAT_SHEEP_EARPLUG:int 	= 8;
		
		public static const CAT_GIFT:int 			= 5;
		public static const CAT_SEAL_NECK:int 		= 6;
		public static const CAT_SEAL_TATTOO:int 	= 7;
		
		public static const CAT_TURTLE_HEAD:int  	= 9;
		public static const CAT_TURTLE_BODY:int     = 10;
		
		public function Shop(singletonEnforcer:SingletonEnforcer) {
		}
		
		public static function get instance(): Shop {
			if(_instance == null) {
				_instance = new Shop(new SingletonEnforcer());
			}
			return _instance;
		}
		
		public function initialize():void {
			itemList = new Vector.<ShopItem>;
			itemList.push(
				// Monkey
				new ShopItem(SKATE_BLUE, StageData.ID_JUNGLE, 5000, false, "Novino 1100-TX skateboard", CAT_SKATE,Shop.STATUS_NO,"Use"),
//				new ShopItem(RED_SKATE, StageData.ID_JUNGLE, 1000, false, "Cool red skate", CAT_SKATE),
				new ShopItem(RED_CAP, StageData.ID_JUNGLE, 600, true, "Red polo cap", CAT_MONKEY_CAP),
				new ShopItem(HAT_BLUE, StageData.ID_JUNGLE, 1500, true, "Blue cowboy hat", CAT_MONKEY_CAP),
				
				// Sheep
				new ShopItem(EAR_PLUG, StageData.ID_SCARY, 1200, true, "Ear Warmer", CAT_SHEEP_EARPLUG),
				new ShopItem(MUFFLER_PINK, StageData.ID_SCARY, 3000, false, "Woolen muffler", CAT_SHEEP_MUFFLER),
				new ShopItem(SHOE_PINK, StageData.ID_SCARY, 5000, false, "Winter shoes", CAT_SHEEP_SHOE),
				
				// Seal
				new ShopItem(CHAIN_GOLD, StageData.ID_BEACH, 7000, false, "Golden locket", CAT_SEAL_NECK),
				new ShopItem(TATTOO_1, StageData.ID_BEACH, 800, false, "Miami Tattoo", CAT_SEAL_TATTOO),
				new ShopItem(RED_GIFT, StageData.ID_BEACH, 1500, true, "Chocolate box", CAT_GIFT,Shop.STATUS_NO,"Get"),
			
				//Turtle
				new ShopItem(GOGGS, StageData.ID_SEA, 2500, false, "Swimming Goggles", CAT_TURTLE_HEAD),
				new ShopItem(EYE_MASK, StageData.ID_SEA, 1500, false, "Ninja Eye Mask", CAT_TURTLE_HEAD),
				new ShopItem(DAGGER, StageData.ID_SEA, 4000, false, "Ninja Dagger", CAT_TURTLE_BODY)

			
			);
			
			itemDict = new Dictionary();
			for(var i:int; i < itemList.length; i++) {
				var item:ShopItem = itemList[i];
				item.status = SharedObjectUtils.getShopItemStatus(item.id);
				
				itemDict[item.id] = item;
			}
		}
		
		public function itemById(id:String):ShopItem {
			if(itemDict[id]) {
				return itemDict[id];
			}
			return null;
		}
		
		public function purchaseItem(id:String):Boolean {
			var item:ShopItem = itemDict[id];
			if(item && GoldManager.instance.goldCount >= item.price) {
				item.status = STATUS_OWN;
				SharedObjectUtils.setShopItemStatus(item.id, STATUS_OWN);
				GoldManager.instance.goldCount -= Shop.instance.itemById(id).price;
			}
			return false;
		}
		
		public function itemsForStage(stageId:int):Vector.<ShopItem> {
			var items:Vector.<ShopItem> = new Vector.<ShopItem>;
			
			for(var i:int; i < itemList.length; i++) {
				if(itemList[i].stageId == stageId) {
					items.push(itemList[i]);
				}
			}
			return items;
		}
		
		private function itemsBought(stageId:int):Vector.<ShopItem> {
			var items:Vector.<ShopItem> = new Vector.<ShopItem>;
			
			var allItems:Vector.<ShopItem> = itemsForStage(stageId);
			for(var i:int; i < allItems.length; i++) {
				if(allItems[i].status > STATUS_NO) {
					items.push(allItems[i]);
				}
			}
			return items;
		}
		
		private function itemsUsing(stageId:int):Vector.<ShopItem> {
			var items:Vector.<ShopItem> = new Vector.<ShopItem>;
			
			var allItems:Vector.<ShopItem> = itemsForStage(stageId);
			for(var i:int; i < allItems.length; i++) {
				if(allItems[i].status == STATUS_USE) {
					items.push(allItems[i]);
				}
			}
			return items;
		}
		
		public function getPostfix(stageId:int, isUpper:Boolean):String {
			var items:Vector.<ShopItem> = itemsUsing(stageId);
			var arr:Array = new Array();
			for(var i:int; i < items.length; i++) {
				if(items[i].isUpper == isUpper)
					arr.push(items[i].id);
			}

			var postfix:String = "";
			if(arr.length) {
				arr.sort();
				postfix = "_" + arr.join("_");
			}
			postfix += "_def";
			
			return postfix;
		}
		
	}
}

internal class SingletonEnforcer {}