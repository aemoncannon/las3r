package com.las3r.errors{

	import flash.events.ErrorEvent;

	public class LispError extends ErrorEvent{
		
		public static const type:String = "lispError"

		public var cause:Error;

		public function LispError(message:String, cause:Error){
			super(type, false, true, message);
			this.cause = cause;
		}

		public function get message():String{
			return text;
		}

	}
}