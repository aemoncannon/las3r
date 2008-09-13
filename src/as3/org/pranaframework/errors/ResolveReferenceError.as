package org.pranaframework.errors {
	/**
	 * Thrown to indicate that a reference could not be resolved. 
 	 * 
 	 * @author Erik Westra
 	 */
	public class ResolveReferenceError extends ReferenceError {
		/**
		 * Constructs a new <code>ResolveReferenceError</code>
		 * 
		 * @param message			The message that should be shown
		 */		
		public function ResolveReferenceError(message:String = "") {
			super(message);
		}
		
	}
}