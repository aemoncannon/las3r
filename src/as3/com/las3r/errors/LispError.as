package com.las3r.errors{

	import flash.events.ErrorEvent;

	public class LispError extends Error{
		

		public function LispError(message:String){
			super(message);
		}

		override public function getStackTrace():String{
			var st:String = super.getStackTrace();
			return st.split("\n").reverse().join("\n");
		}

	}
}