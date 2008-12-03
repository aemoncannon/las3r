package com.cuttlefish.util {
	import flash.events.*;
	import flash.display.*;
	import flash.utils.*;
	
	public class ExecHelper {


		private static var _globalFrameQ:Array = [];

		private static var _globalTimer:Timer;
		private static var _globalTimeQ:Array = [];

		
		public static function doOnNextFrame(dispatcher:DisplayObject, workUnit:Function, wait:int = 0):void{
			var count:int = 0;
			dispatcher.addEventListener(Event.ENTER_FRAME, function(e:Event){
					if(count >= wait){
						workUnit();
						dispatcher.removeEventListener(Event.ENTER_FRAME, arguments.callee);
					}
					count++;
				});
		}

		public static function overFrames(numFrames:int, workUnit:Function, finished:Function, dispatcher:DisplayObject):void{
			var count:int = 0;
			dispatcher.addEventListener(Event.ENTER_FRAME, function(e:Event){
					if(count < numFrames){
						workUnit(count);
					}
					else{
						finished();
						dispatcher.removeEventListener(Event.ENTER_FRAME, arguments.callee);
					}
					count ++;
				});
		}


		public static function executeInGlobalFrameQueue(workUnit:Function, dispatcher:DisplayObject):void{
			if(_globalFrameQ.length == 0){
				dispatcher.addEventListener(Event.ENTER_FRAME, function(e:Event){
						if(_globalFrameQ.length > 0){
							(_globalFrameQ[0])();
							_globalFrameQ.splice(0, 1);
						}
						else{
							dispatcher.removeEventListener(Event.ENTER_FRAME, arguments.callee);
							return;
						}
					});
			}
			_globalFrameQ.push(workUnit);
		}

		public static function executeInGlobalTimeQueue(workUnit:Function, dispatcher:DisplayObject):void{
			if(!_globalTimer){
				_globalTimer = new Timer(10);
				_globalTimer.addEventListener(TimerEvent.TIMER, function(e:Event){
						if(_globalTimeQ.length > 0){
							(_globalTimeQ[0])();
							_globalTimeQ.splice(0, 1);
						}
						else{
							_globalTimer.stop();
							return;
						}
					});
			}
			if(_globalTimeQ.length == 0){
				_globalTimer.start();

			}
			_globalTimeQ.push(workUnit);
		}
	}
}