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
 	
 	import org.pranaframework.errors.IllegalArgumentError;
	
	/**
	 * Contains utility methods for working with strings.
	 * 
	 * @author Christophe Herreman
	 * @author Martin Heidegger (as2lib)
	 * @author Simon Wacker (as2lib)
	 */
	public class StringUtils {
		
		/**
		 * Adds/inserts a new string at a certain position in the source string.
		 */
		public static function addAt(string:String, value:*, position:int):String {
			if (position > string.length) {
				position = string.length;
			}
			var firstPart:String = string.substring(0, position);
			var secondPart:String = string.substring(position, string.length);
			return (firstPart + value + secondPart);
		}
		
		/**
		 * Replaces a part of the text between 2 positions.
		 */
		public static function replaceAt(string:String, value:*, beginIndex:int, endIndex:int):String {
			beginIndex = Math.max(beginIndex, 0)
			endIndex = Math.min(endIndex, string.length);
			var firstPart:String = string.substr(0, beginIndex);
			var secondPart:String = string.substr(endIndex, string.length);
			return (firstPart + value + secondPart);
		}
		
		/**
		 * Removes a part of the text between 2 positions.
		 */
		public static function removeAt(string:String, beginIndex:int, endIndex:int):String {
			return StringUtils.replaceAt(string, "", beginIndex, endIndex);
		}
		
		/**
		 * Fixes double newlines in a text.
		 */
		public static function fixNewlines(string:String):String {
			return string.replace(/\r\n/gm, "\n");
		}
		
		/**
		 * Checks if the given string has actual text.
		 */
		public static function hasText(string:String):Boolean {
			return (StringUtils.trim(string).length > 0);
		}
		
		/**
		 * Removes all empty characters at the beginning and at the end of the passed-in
		 * {@code string}.
		 *
		 * <p>Characters that are removed: spaces {@code " "}, line forwards {@code "\n"}
		 * and extended line forwarding {@code "\t\n"}.
		 *
		 * @param string the string to trim
		 * @return the trimmed string
		 */
 	        public static function trim(string:String):String {
 	                return leftTrim(rightTrim(string));
 	        }
 	       
 	        /**
 	         * Removes all empty characters at the beginning of a string.
 	         *
 	         * <p>Characters that are removed: spaces {@code " "}, line forwards {@code "\n"}
 	         * and extended line forwarding {@code "\t\n"}.
 	         *
 	         * @param string the string to trim
 	         * @return the trimmed string
 	         */
 	        public static function leftTrim(string:String):String {
 	                return leftTrimForChars(string, "\n\t\n ");
 	        }
 	
 	        /**
 	         * Removes all empty characters at the end of a string.
 	         *
 	         * <p>Characters that are removed: spaces {@code " "}, line forwards {@code "\n"}
	         * and extended line forwarding {@code "\t\n"}.
 	         *
 	         * @param string the string to trim
 	         * @return the trimmed string
 	         */     
 	        public static function rightTrim(string:String):String {
 	                return rightTrimForChars(string, "\n\t\n ");
 	        }
 	       
 	        /**
 	         * Removes all characters at the beginning of the {@code string} that match to the
 	         * set of {@code chars}.
 	         *
 	         * <p>This method splits all {@code chars} and removes occurencies at the beginning.
 	         *
 	         * <p>Example:
 	         * <code>
 	         *   trace(StringUtil.rightTrimForChars("ymoynkeym", "ym")); // oynkeym
 	         *   trace(StringUtil.rightTrimForChars("monkey", "mo")); // nkey
 	         *   trace(StringUtil.rightTrimForChars("monkey", "om")); // nkey
 	         * </code>
 	         *
 	         * @param string the string to trim
 	         * @param chars the characters to remove from the beginning of the {@code string}
 	         * @return the trimmed string
 	         */
 	        public static function leftTrimForChars(string:String, chars:String):String {
 	                var from:Number = 0;
 	                var to:Number = string.length;
 	                while (from < to && chars.indexOf(string.charAt(from)) >= 0){
 	                        from++;
 	                }
 	                return (from > 0 ? string.substr(from, to) : string);
 	        }
 	       
 	        /**
 	         * Removes all characters at the end of the {@code string} that match to the set of
 	         * {@code chars}.
 	         *
 	         * <p>This method splits all {@code chars} and removes occurencies at the end.
 	         *
 	         * <p>Example:
 	         * <code>
 	         *   trace(StringUtil.rightTrimForChars("ymoynkeym", "ym")); // ymoynke
 	         *   trace(StringUtil.rightTrimForChars("monkey***", "*y")); // monke
 	         *   trace(StringUtil.rightTrimForChars("monke*y**", "*y")); // monke
 	         * </code>
 	         *
 	         * @param string the string to trim
 	         * @param chars the characters to remove from the end of the {@code string}
 	         * @return the trimmed string
 	         */
 	        public static function rightTrimForChars(string:String, chars:String):String {
 	                var from:Number = 0;
 	                var to:Number = string.length - 1;
 	                while (from < to && chars.indexOf(string.charAt(to)) >= 0) {
 	                        to--;
 	                }
 	                return (to >= 0 ? string.substr(from, to+1) : string);
	        }
 	       
 	        /**
 	         * Removes all characters at the beginning of the {@code string} that matches the
	         * {@code char}.
 	         *
 	         * <p>Example:
 	         * <code>
 	         *   trace(StringUtil.leftTrimForChar("yyyymonkeyyyy", "y"); // monkeyyyy
 	         * </code>
 	         *
 	         * @param string the string to trim
 	         * @param char the character to remove
 	         * @return the trimmed string
 	         * @throws IllegalArgumentException if you try to remove more than one character
 	         */
 	        public static function leftTrimForChar(string:String, char:String):String {
 	                if(char.length != 1) {
 	                        throw new IllegalArgumentError("The Second Attribute char [" + char + "] must exactly one character.");
 	                }
 	                return leftTrimForChars(string, char);
 	        }
 	       
 	        /**
 	         * Removes all characters at the end of the {@code string} that matches the passed-in
 	         * {@code char}.
 	         *
 	         * <p>Example:
 	         * <code>
 	         *   trace(StringUtil.rightTrimForChar("yyyymonkeyyyy", "y"); // yyyymonke
 	         * </code>
 	         *
 	         * @param string the string to trim
 	         * @param char the character to remove
 	         * @return the trimmed string
	         * @throws IllegalArgumentException if you try to remove more than one character
 	         */
 	        public static function rightTrimForChar(string:String, char:String):String {
 	                if(char.length != 1) {
 	                        throw new IllegalArgumentError("The Second Attribute char [" + char + "] must exactly one character.");
 	                }
 	                return rightTrimForChars(string, char);
 	        }
	}
}