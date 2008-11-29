package com.las3r.errors{

	import flash.events.ErrorEvent;

	public class LispError extends ErrorEvent{
		
		public var cause:*;

		public static const LISP_ERROR:String = "lispError";

		public function LispError(message:String, cause:*){
			super(LISP_ERROR, false, true, message);
			this.cause = cause;
		}

		public function get message():String{
			return text;
		}

		override public function toString():String{
			return message + (cause is Error ? cause.getStackTrace() : "");
		}

	}
}