/**
 * Copyright (c) 2007-2008, the original author(s)
 * 
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 *     * Redistributions of source code must retain the above copyright notice,
 *       this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the Prana Framework nor the names of its contributors
 *       may be used to endorse or promote products derived from this software
 *       without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
 package org.pranaframework.utils {
	
	import flash.utils.Dictionary;
	
	import org.pranaframework.errors.IllegalArgumentError;
	import org.pranaframework.errors.IllegalStateError;
	
	/**
	 * Assertion utility class that assists in validating arguments.
	 * Useful for identifying programmer errors early and clearly at runtime.
	 * 
	 * Note: this class is based on the Assert class in java's Spring framework.
	 * 
	 * @author Christophe Herreman
	 * @see http://fisheye1.cenqua.com/browse/~raw,r=1.27/springframework/spring/src/org/springframework/util/Assert.java
	 */
	public class Assert {
		
		/**
		 * Assert that an object is <code>null</code>.
		 * <pre class="code">Assert.isNull(value, "The value must be null");</pre>
		 * @param object the object to check
		 * @param message the error message to use if the assertion fails
		 * @throws IllegalArgumentError if the object is not <code>null</code>
		 */
		public static function notNull(object:Object, message:String = ""):void {
			if (message == "" || message == null) {
				message = "[Assertion failed] - this argument is required; it must not null";
			}
			if (object == null) {
				throw new IllegalArgumentError(message);
			}
		}
		
		/**
		 * Assert that an object is an instance of a certain type..
		 * <pre class="code">Assert.instanceOf(value, type, "The value must be an instance of 'type'");</pre>
		 * @param object the object to check
		 * @param message the error message to use if the assertion fails
		 * @throws IllegalArgumentError if the object is not an instance of the given type
		 */
		public static function instanceOf(object:*, type:Class, message:String = ""):void {
			if (message == "" || message == null) {
				message = "[Assertion failed] - this argument is not of type '" + type + "'";
			}
			if (!(object is type)) {
				throw new IllegalArgumentError(message);
			}
		}
		
		/**
		 * Asserts that a class is a subclass of another class.
		 */
		public static function subclassOf(clazz:Class, parentClass:Class, message:String = ""):void {
			if (message == "" || message == null) {
				message = "[Assertion failed] - this argument is not a subclass of '" + parentClass + "'";
			}
			if (!ClassUtils.isSubclassOf(clazz, parentClass)) {
				throw new IllegalArgumentError(message);
			}
		}
		
		/**
		 * Assert that an object implements a certain interface.
		 */
		public static function implementationOf(object:*, interfaze:Class, message:String = ""):void {
			if (message == "" || message == null) {
				message = "[Assertion failed] - this argument does not implement the interface '" + interfaze + "'";
			}
			if (!ClassUtils.isImplementationOf(ClassUtils.forInstance(object), interfaze)) {
				throw new IllegalArgumentError(message);
			}
		}
		
		/**
		 * Assert a boolean expression to be true. If false, an IllegalStateError is thrown.
		 * @param expression a boolean expression
		 * @param the error message if the assertion fails
		 */
		public static function state(expression:Boolean, message:String = ""):void {
			if (message == "" || message == null) {
				message = "[Assertion failed] - this state invariant must be true";
			}
			if (!expression) {
				throw new IllegalStateError(message);
			}
		}
		
		/**
		 * Assert that the given String has valid text content; that is, it must not
		 * be <code>null</code> and must contain at least one non-whitespace character.
		 * 
		 * @param text the String to check
		 * @param message the exception message to use if the assertion fails
		 * @see StringUtils#hasText
		 */
		public static function hasText(string:String, message:String = ""):void {
			if (message == "" || message == null) {
				message = "[Assertion failed] - this String argument must have text; it must not be <code>null</code>, empty, or blank";
			}
			if (!StringUtils.hasText(string)) {
				throw new IllegalArgumentError(message);
			}
		}
		
		/**
		 * Assert that the given Dictionary contains only keys of the given type.
		 */
		public static function dictionaryKeysOfType(dictionary:Dictionary, type:Class, message:String = ""):void {
			if (message == "" || message == null) {
				message = "[Assertion failed] - this Dictionary argument must have keys of type '" + type + "'";
			}
			for (var key:Object in dictionary) {
				if (!(key is type)) {
					throw new IllegalArgumentError(message);
				}
			}
		}
		
		/**
		 * Assert that the array contains the passed in item.
		 */
		public static function arrayContains(array:Array, item:*, message:String = ""):void {
			if (message == "" || message == null) {
				message = "[Assertion failed] - this Array argument does not contain the item '" + item + "'";
			}
			if (array.indexOf(item) == -1) {
				throw new IllegalArgumentError(message);
			}
		}
	}
}