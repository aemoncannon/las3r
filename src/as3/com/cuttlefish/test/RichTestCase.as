/**
* Copyright (c) Aemon Cannon. All rights reserved.
* The use and distribution terms for this software are covered by the
* Common Public License 1.0 (http://opensource.org/licenses/cpl.php)
* which can be found in the file CPL.TXT at the root of this distribution.
* By using this software in any fashion, you are agreeing to be bound by
* the terms of this license.
* You must not remove this notice, or any other, from this software.
*/


package com.cuttlefish.test{
	import flexunit.framework.TestCase;
 	import flexunit.framework.TestSuite;
 	import flash.events.*;
 	import flash.external.*;
 	import flash.utils.*;

	public class RichTestCase extends TestCase {

		protected function assertThrows(msg:String, func:Function, pred:Function = null):void{
			var errorPred = pred || function(e:*):Boolean{ return true; }
			var thrown:Boolean = false;
			try{
				func();
			}
			catch(e:*){
				if(errorPred(e)){ thrown = true;}
			}
			if(!thrown){ fail(msg); }
		}


		protected function assertDispatches(dispatcher:EventDispatcher, type:String, msg:String, func:Function):void{
			var listener:Function = willCall(function(e:*):void{ dispatcher.removeEventListener(type, listener); }, 5000);
			dispatcher.addEventListener(type, listener);
			func();
		}


		/**
		* For function 'func', return a function g, wrapping func,  with the same signature, for which the testcase will wait before
		* continuing.
		* 
		* @param func The function to wrap.
		* @param timeout The amount of time to wait for g to be invoked.
		* @param pause The amount of time AFTER invocation that the testing procedure will wait.
		* @param failFunc 
		* @return 
		*/		
		protected function willCall(func : Function, timeout:int, pause:int = 0, failFunc : Function = null) : Function
		{
			if(pause > timeout){ throw "In willCall, pause must be less than timeout."}
			
			var eventHandler:Function = addAsync(
				function(e:Event):void{},
				timeout, 
				null, 
				failFunc
			);

			return function(...args:Array):void{
				func.apply( this, args);
				setTimeout(function():void{
						eventHandler(new Event("IGNORE"));
					}, pause);
			}
		}

		protected function ffTrace(val:String):void{
			ExternalInterface.call("console.log", val);
		}

		protected function ieAlert(val:String):void{
			ExternalInterface.call("alert", val);
		}

		/* Expects arguments of the form:
		*  [target:EventDispatcher, eventType:String, function(){}],[],....
        */
		protected function eventChain(kickoff:Function, ...items:Array):void{
			eventChainHelper(items);
			kickoff();
		}

		private function eventChainHelper(items:Array):void{
			if(items.length > 0){
				var item:Array = items[0];
				var target:* = item[0];
				var eventType:String = item[1];
				var listener:Function = item[2];
				var rest:Array = items.slice(1, items.length);
				target.addEventListener(eventType, function(e:*):void{
						target.removeEventListener(eventType, arguments.callee);
						eventChainHelper(rest);
						listener(e);
					});
			}
		}

	}
}

