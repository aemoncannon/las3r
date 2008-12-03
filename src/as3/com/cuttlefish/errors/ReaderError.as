package com.cuttlefish.errors{

	public class ReaderError extends LispError{

		public function ReaderError(message:String, cause:*){
			super(message, cause);
		}

	}
}