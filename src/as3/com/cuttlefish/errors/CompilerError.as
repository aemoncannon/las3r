package com.cuttlefish.errors{

	public class CompilerError extends LispError{

		public function CompilerError(message:String, cause:*){
			super(message, cause);
		}

	}
}