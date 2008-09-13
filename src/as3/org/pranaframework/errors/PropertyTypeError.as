package org.pranaframework.errors {
	/**
	 * Thrown to indicate that a property was given an object of the wrong type. 
 	 * 
 	 * @author Erik Westra
 	 */
	public class PropertyTypeError extends TypeError {
		/**
		 * Constructs a new <code>PropertyTypeError</code>
		 * 
		 * @param message			The message that should be shown
		 */
		public function PropertyTypeError(message:String= "") {
			super(message);
		}
	}
}