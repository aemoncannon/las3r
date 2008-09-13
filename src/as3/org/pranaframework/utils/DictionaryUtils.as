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
	
	/**
	 * Contains utilities for working with Dictionaries.
	 * 
	 * @author Christophe Herreman
	 */
	public class DictionaryUtils {
		
		/**
		 * Returns an array with the keys of the dictionary.
		 * 
		 */
		public static function getKeys(dictionary:Dictionary):Array {
			return ObjectUtils.getKeys(dictionary);
		}
		
		/**
		 * Check whether the given dictionary contains the given key.
		 * 
		 * @param dictionary the dictionary to check for a key
		 * @param key the key to look up in the dictionary
		 * @return <code>true</code> if the dictionary contains the given key, <code>false</code> if not
		 */
		public static function containsKey(dictionary:Dictionary, key:Object):Boolean {
			var result:Boolean = false;
			for (var k:* in dictionary) {
				if (key === k) {
					result = true;
					break;
				}
			}
			return result;
		}
		
		/**
		 * Check whether the given dictionary contains the given value.
		 * 
		 * @param dictionary the dictionary to check for a value
		 * @param value the value to look up in the dictionary
		 * @return <code>true</code> if the dictionary contains the given value, <code>false</code> if not
		 */
		public static function containsValue(dictionary:Dictionary, value:Object):Boolean {
			var result:Boolean = false;
			for each (var i:* in dictionary) {
				if (i === value) {
					result = true;
					break;
				}
			}
			return result;
		}

	}
}