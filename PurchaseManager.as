package managers
{
CONFIG::ios {
	import com.adobe.ane.productStore.Product;
	import com.adobe.ane.productStore.ProductEvent;
	import com.adobe.ane.productStore.ProductStore;
	import com.adobe.ane.productStore.Transaction;
	import com.adobe.ane.productStore.TransactionEvent;
	import com.gamua.flox.utils.Base64;
	
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
}
CONFIG::android {
	import com.pozirk.payment.android.InAppPurchase;
	import com.pozirk.payment.android.InAppPurchaseDetails;
	import com.pozirk.payment.android.InAppPurchaseEvent;
}
	
	import com.sticksports.nativeExtensions.flurry.Flurry;
	
	import flash.events.Event;
	
	import core.Utils;
	import objects.GetGoldPopup;
	
	/**
	 * 		Google Play In-App Billing v3 + Adobe ProductStore ANE for iOS.
	 * 		http://github.com/pozirk/AndroidInAppPurchase
	 */	
	public class PurchaseManager
	{
		private static var _instance:PurchaseManager;
		CONFIG::ios {
			private var storeIOS:ProductStore;
			
			private const PROD_VERIFY_RECEIPT:String 		= "https://buy.itunes.apple.com/verifyReceipt";
			private const SANDBOX_VERIFY_RECEIPT:String 	= "https://sandbox.itunes.apple.com/verifyReceipt";
		}
		CONFIG::android {
			private var storeAndroid:InAppPurchase;
			
			private const GOOGLE_PLAY_KEY:String = "MIIBCgKCAQEAo4g5miq9NN7DSMdHnUfiNlJAAgxIpAFzbDTzty7e85JEYhzmVTxdGzr22OPikNDIWZ3z9VYKQo7TEqmCDyRgj6R2C9gJyJXtIh3g4PQJ/pW0dfNwIPF9Olvt5+qva4yEM6EI9Mcw7waFr0BUXzjuvQx6n2eoXnkHzQnH8T9IMOkTLkhK6e04H/cH3nZb0h6V8/RozOy6yxBOFb/r7CDlfOysfJHhW6aKtdq4SWyO2ooweBcceabSflOdtBn0iRfChM2gdy/2gR+t09sY3G+dqEL9Nktxb4ZpXYokK3Y5bNQYyL38365FA9B9bCEpe9Tm9OcwQIDAQAB";
		}
		
		public static const GOLD_PACKS:Array = [2000, 8000, 20000];
		public static const GOLD_PACK_PRICES:Array = [0.99, 1.99, 3.99];
		private static const items:Array = ["gold_pack_1", "gold_pack_2", "gold_pack_3"];
		
		public var debug:Boolean = true;
		
		public function PurchaseManager(singletonEnforcer:SingletonEnforcer)
		{
		}
		
		public static function get instance(): PurchaseManager {
			if(_instance == null) {
				_instance = new PurchaseManager(new SingletonEnforcer());
			}
			return _instance;
		}
		
		private var _onInit:Function;
		private var _isReady:Boolean;
		
		public function initialize(onInitCb:Function = null):void {
			if(_isReady || Utils.isSimulator || !isSupported() || !Utils.isConnected) {
				if(onInitCb != null)
					onInitCb();
				return;
			}
			
			_onInit = onInitCb;
			
			CONFIG::ios {
				storeIOS = new ProductStore();
				
				if(storeIOS.available) 
					getProductDetails();
			}
			CONFIG::android {
				storeAndroid = new InAppPurchase();
				
				storeAndroid.addEventListener(InAppPurchaseEvent.INIT_SUCCESS, onInitSuccess);
				storeAndroid.addEventListener(InAppPurchaseEvent.INIT_ERROR, onInitError);
				
				storeAndroid.addEventListener(InAppPurchaseEvent.PURCHASE_ALREADY_OWNED, onAlreadyOwned);
				storeAndroid.addEventListener(InAppPurchaseEvent.PURCHASE_SUCCESS, onPurchaseSuccess);
				storeAndroid.addEventListener(InAppPurchaseEvent.PURCHASE_ERROR, onPurchaseError);
				
				storeAndroid.addEventListener(InAppPurchaseEvent.RESTORE_SUCCESS, onRestoreSuccessAndroid);
				storeAndroid.addEventListener(InAppPurchaseEvent.RESTORE_ERROR, onRestoreError);
				
				storeAndroid.addEventListener(InAppPurchaseEvent.CONSUME_SUCCESS, onConsumeSuccess);
				storeAndroid.addEventListener(InAppPurchaseEvent.CONSUME_ERROR, onConsumeError);
				
				storeAndroid.init(GOOGLE_PLAY_KEY);
				
				onReady();
			}
			
		}
		
		private function onReady():void {
			_isReady = true;
			
			CONFIG::ios {
				if(_pendingBuy) {
					_pendingBuy = false;
					
					CONFIG::test {
						Utils.toast("Buying pending IAP...");
					}
					buyGold(_goldPackId, _goldBuyCB);
				}
			}
		}
		
		private var _goldBuyCB:Function;
		private var _goldPackId:int;
		private var _pendingBuy:Boolean;
		
		public function buyGold(packId:int /*1 indexed*/, onBuySuccess:Function = null):void {
			_goldPackId = packId;
			_goldBuyCB = onBuySuccess;
			
			if(Utils.isSimulator) {
				onPurchaseSuccess(null);
				return;
			}
			
			if(!Utils.isConnected) {
				Utils.networkError();
				return;
			}
			
			CONFIG::ios {
				if(!_isReady) {
					_pendingBuy = true;
					
					if(!_gettingDetails) {
						initialize();
					}
					CONFIG::test {
						Utils.toast("IAP not ready, Waiting to Buy...");
					}
					return;
				}
			}

			CONFIG::ios {
				storeIOS.addEventListener(TransactionEvent.PURCHASE_TRANSACTION_SUCCESS, onTransactionSuccess);
				storeIOS.addEventListener(TransactionEvent.PURCHASE_TRANSACTION_CANCEL, onTransactionCancel);
				storeIOS.addEventListener(TransactionEvent.PURCHASE_TRANSACTION_FAIL, onTransactionFail);
				storeIOS.makePurchaseTransaction("gold_pack_" + packId);
				popupTouchable = false;
			}
			CONFIG::android {
				storeAndroid.purchase("gold_pack_" + packId, InAppPurchaseDetails.TYPE_INAPP);
			}
		}
		
		private function set popupTouchable(value:Boolean):void {
			var popup:GetGoldPopup = PopupManager.getPopup(GetGoldPopup) as GetGoldPopup;
			if(popup) {
				popup.buttonsTouchable = value;
			}
		}
		
		private function onPurchaseSuccess(event:Event = null):void {
			if(debug) Utils.tracer("Billing:", "onPurchase Success :", (event ? event : ""));
			
			popupTouchable = true;
			
			Flurry.logEvent("Get gold popup - bought -" + _goldPackId);
			Utils.goldRewarded(GOLD_PACKS[_goldPackId - 1]);
			_goldPackId = 0;
			
			if(_goldBuyCB != null) {
				_goldBuyCB();
				_goldBuyCB = null;
			}
			
			// save sale in shared object
			
			CONFIG::android {
				if(storeAndroid){
					storeAndroid.restore(items);
				}
			}
		}
		
		private function onInitSuccess(event:Event = null):void {
			if(debug) Utils.tracer("Billing:", "Init Success");
			
			CONFIG::android {
				storeAndroid.restore();
			}
		}
		
		private function onInitError(event:Event):void {
			if(debug) Utils.tracer("Billing:", "Init Error :", event);
		}
		
		private function isSupported():Boolean {
			CONFIG::android {
				return true;
			}
			CONFIG::ios {
				return ProductStore.isSupported;
			}
			return false;
		}
		
	CONFIG::ios {
		private var _gettingDetails:Boolean;
		public function getProductDetails():void {
			storeIOS.addEventListener(ProductEvent.PRODUCT_DETAILS_SUCCESS, onProductDetailsSuccess);
			storeIOS.addEventListener(ProductEvent.PRODUCT_DETAILS_FAIL, onProductDetailsFail);
			
			var vector:Vector.<String> = new Vector.<String>;
			for each(var item:String in items) {
				vector.push(item);
			}
			
			_gettingDetails = true;
			storeIOS.requestProductsDetails(vector);
		}
		
		
		private function onProductDetailsSuccess(e:ProductEvent):void {
			getPendingTransaction(storeIOS);

			_gettingDetails = false;
			onReady();
			
			CONFIG::test {
				var prices:String = "";
				for each(var product:Product in e.products) {
					prices += product.price + ", ";
				}
				Utils.toast("IAP Ready. Prices: " + prices);
			}
		}
		
		private function onProductDetailsFail(e:ProductEvent):void {
			var i:uint=0;
			while(e.invalidIdentifiers && i < e.invalidIdentifiers.length) {
				trace(e.invalidIdentifiers[i]);
				i++;
			}
		}
		
		private function validateTransaction(t:Transaction):void {
			var encodedReceipt:String = Base64.encode(t.receipt ? t.receipt : "");
			var req:URLRequest = new URLRequest(PROD_VERIFY_RECEIPT);
			req.method = URLRequestMethod.POST;
			req.data = "{\"receipt-data\" : \""+ encodedReceipt+ "\"}";
			
			var ldr:URLLoader = new URLLoader(req);
			ldr.addEventListener(Event.COMPLETE, onComplete);
			ldr.load(req);
		
			function onComplete(e:Event):void {
				//var loader:URLLoader = e.target as URLLoader;
				var data:Object = JSON.parse(ldr.data);
				//trace("LOAD COMPLETE: " + data);
				
				if(data.status == 0 && data.hasOwnProperty("receipt")) {	//data.hasOwnProperty("status") && data.status == 21007) {
					trace("receipt validated!!!");
					onPurchaseSuccess();
					storeIOS.addEventListener(TransactionEvent.FINISH_TRANSACTION_SUCCESS, onFinishTransactionSuccess);
					storeIOS.finishTransaction(t.identifier);
					ldr.removeEventListener(Event.COMPLETE, onComplete);
					ldr = null;	req = null;	t = null;
					
				}else if(data.status == 21007) {
					trace("production validation failed, trying sandbox now...");
					req.url = SANDBOX_VERIFY_RECEIPT;
					ldr.load(req);
					
				}else {
					trace("validation has failed!!!");
					storeIOS.addEventListener(TransactionEvent.FINISH_TRANSACTION_SUCCESS, onFinishTransactionSuccess);
					storeIOS.finishTransaction(t.identifier);
					ldr.removeEventListener(Event.COMPLETE, onComplete);
					ldr = null;	req = null;	t = null;
				}
			}
			
		}
		
		
		private function onTransactionSuccess(e:TransactionEvent):void {
			trace("on Transaction success, validating now...");
			for each(var t:Transaction in e.transactions) {
				validateTransaction(t);
			}
		}
		
		private function onTransactionCancel(e:TransactionEvent):void {
			popupTouchable = true;
			
			trace("transaction cancelled " + e);
			for each(var t:Transaction in e.transactions) {
				printTransaction(t);
				
				trace("finishing transaction " + t.identifier);
				storeIOS.addEventListener(TransactionEvent.FINISH_TRANSACTION_SUCCESS, onFinishTransactionSuccess);
				storeIOS.finishTransaction(t.identifier);
			}
			
			getPendingTransaction(storeIOS);
		}
		
		private function onTransactionFail(e:TransactionEvent):void {
			popupTouchable = true;
			
			trace("transaction failed " + e);
			for each(var t:Transaction in e.transactions) {
				printTransaction(t);

				storeIOS.addEventListener(TransactionEvent.FINISH_TRANSACTION_SUCCESS, onFinishTransactionSuccess);
				storeIOS.finishTransaction(t.identifier);
			}
			
			getPendingTransaction(storeIOS);
		}
		
		private function onFinishTransactionSuccess(e:TransactionEvent):void {
			popupTouchable = true;
			
			trace("transaction finished -------------");
			for each(var t:Transaction in e.transactions) {
				printTransaction(t);
			}
		}
		
		public function getPendingTransaction(prdStore:ProductStore):void {
			var transactions:Vector.<Transaction> = prdStore.pendingTransactions;
			if(transactions)
				trace(transactions.length, "pending transactions");
			
//			storeIOS.addEventListener(TransactionEvent.FINISH_TRANSACTION_SUCCESS, onFinishTransactionSuccess);
			for each(var t:Transaction in transactions) {
//				validateTransaction(t);
				
				trace("finishing transaction " + t.identifier + " ...");
				storeIOS.addEventListener(TransactionEvent.FINISH_TRANSACTION_SUCCESS, onFinishTransactionSuccess);
				storeIOS.finishTransaction(t.identifier);
			}
		}
		
		public function printTransaction(t:Transaction):void
		{
			/*
			trace("-------------------in Print Transaction----------------------");
			trace("identifier :"+t.identifier);
			trace("productIdentifier: "+ t.productIdentifier);
			trace("productQuantity: "+t.productQuantity);
			trace("date: "+t.date);
			trace("receipt: "+t.receipt);
			trace("error: "+t.error);
			trace("originalTransaction: "+t.originalTransaction);
			if(t.originalTransaction)
				printTransaction(t.originalTransaction);
			trace("---------end of print transaction----------------------------");
			*/
		}
		
		// RESTORE: for non-consumables
		
		public function restorePurchase():void
		{
			trace("in restore_Transactions");
			storeIOS.addEventListener(TransactionEvent.RESTORE_TRANSACTION_SUCCESS, onRestoreSuccessIOS);
			storeIOS.addEventListener(TransactionEvent.RESTORE_TRANSACTION_FAIL, onRestoreFail);
			storeIOS.addEventListener(TransactionEvent.RESTORE_TRANSACTION_COMPLETE,  onRestoreComplete);
			storeIOS.restoreTransactions();
		}
		
		private function onRestoreSuccessIOS(e:TransactionEvent):void{
			
			trace("in restoreTransactionSucceeded" +e);
			
			for each(var t:Transaction in e.transactions) {
				printTransaction(t);
				
				trace("FinishTransactions" + t.identifier);
				storeIOS.addEventListener(TransactionEvent.FINISH_TRANSACTION_SUCCESS, onFinishTransactionSuccess);
				storeIOS.finishTransaction(t.identifier);
			}
			
			//getPendingTransaction(store);
		}
		
		private function onRestoreFail(e:TransactionEvent):void {
			trace("in restoreTransactionFailed" +e);
		}
		
		private function onRestoreComplete(e:TransactionEvent):void {
			trace("in restoreTransactionCompleted" +e);
		}
		
	}
	
	CONFIG::android {
		private function onPurchaseError(event:InAppPurchaseEvent):void {
			if(debug) Utils.tracer("Billing:", "onPurchase Error :", event.data);
			
			if(storeAndroid){
				storeAndroid.restore();
			}
		}
		
		private function onAlreadyOwned(event:InAppPurchaseEvent):void {
			if(debug) Utils.tracer("Billing:", "Already owned :", event.data);
			
			if(storeAndroid){
				storeAndroid.restore();
			}
			//var purchaseDetails:InAppPurchaseDetails = iap.getPurchaseDetails("gold_pack_100");
			//if(debug) Utils.tracer("Billing:", purchaseDetails._orderId, purchaseDetails._payload, purchaseDetails._signature);
		}
		
		private function onConsumeSuccess(event:InAppPurchaseEvent):void {
			if(debug) Utils.tracer("Billing:", "Consume Success :", event.data);
			if(event.data == "gold_pack_" + _goldPackId && _goldBuyCB) {
				buyGold(_goldPackId, _goldBuyCB);
			}
		}
		
		private function onConsumeError(event:InAppPurchaseEvent):void {
			if(debug) Utils.tracer("Billing:", "Consume Error :", event.data);
		}
		
		private function onRestoreSuccessAndroid(event:InAppPurchaseEvent):void {
			if(debug) Utils.tracer("Billing:", "Restore Success :", event.data);
			
			storeAndroid.consume("gold_pack_1");
			storeAndroid.consume("gold_pack_2");
			storeAndroid.consume("gold_pack_3");
		}
		
		private function onRestoreError(event:InAppPurchaseEvent):void {
			if(debug) Utils.tracer("Billing:", "Restore Error :", event.data);
		}
	}
		
	}
}

internal class SingletonEnforcer {}