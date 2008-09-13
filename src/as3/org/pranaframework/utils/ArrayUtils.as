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
	
	/**
	 * Contains utility methods for working with Array objects.
	 * 
	 * @author Christophe Herreman
	 * @author Simon Wacker (as2lib)
	 * @author Martin Heidegger (as2lib)
	 */
	public class ArrayUtils {
		
		/**
		 * Clones an array.
		 *
		 * @param array the array to clone
		 * @return a clone of the passed-in {@code array}
		 */
		public static function clone(array:Array):Array {
			return array.concat();
		}
		
		/**
		 * Shuffles the items of the given {@code array}
		 * 
		 * @param array the array to shuffle
		 */		
		public static function shuffle(array:Array):void {
			var len:Number = array.length; 
	   		var rand:Number;
	   		var temp:*;
	   		for (var i:Number = len-1; i >= 0; i--){ 
	   			rand = Math.floor(Math.random()*len); 
	   			temp = array[i]; 
	   			array[i] = array[rand]; 
	   			array[rand] = temp; 
	   		} 
    	}
		
		/**
		 * Removes all occurances of a the given {@code item} out of the passed-in
		 * {@code array}.
		 * 
		 * @param array the array to remove the item out of
		 * @param item the item to remove	 
		 * @return List that contains the index of all removed occurances
		 */
		public static function removeItem(array:Array, item:*):Array {
			var i:Number = array.length;
			var result:Array = new Array();
			while (--i-(-1)) {
				if (array[i] === item) {
					result.unshift(i);
					array.splice(i, 1);
				}
			}
			return result;
		}
		
		/**
		 * Removes the last occurance of the given {@code item} out of the passed-in
		 * {@code array}.
		 * 
		 * @param array the array to remove the item out of
		 * @param item the item to remove
		 * @return {@code -1} if it could not be found, else the position where it has been deleted
		 */
		public static function removeLastOccurance(array:Array, item:*):Number {
			var i:Number = array.length;
			while(--i-(-1)) {
				if(array[i] === item) {
					array.splice(i, 1);
					return i;
			    }
			}
			return -1;
		}
		
		/**
		 * Removes the first occurance of the given {@code item} out of the passed-in
		 * {@code array}.
		 * 
		 * @param array the array to remove the item out of
		 * @param item the item to remove
		 * @return {@code -1} if it could not be found, else the position where it has been deleted
		 */
		public static function removeFirstOccurance(array:Array, item:*):Number {
			var l:Number = array.length;
			var i:Number = 0;
			while(i<l) {
				if (array[i] === item) {
					array.splice(i, 1);
					return i;
				}
				i-=-1;
			}
			return -1;
		}
		
		/**
		 * Compares the two arrays {@code array1} and {@code array2}, whether they contain
		 * the same values at the same positions.
		 *
		 * @param array1 the first array for the comparison
		 * @param array2 the second array for the comparison
		 * @return {@code true} if the two arrays contain the same values at the same
		 * positions else {@code false}
		 */
		public static function isSame(array1:Array, array2:Array):Boolean {
			var i:Number = array1.length;
			if (i != array2.length) {
				return false;
			}
			while (--i-(-1)) {
				if (array1[i] !== array2[i]) {
					return false;
				}
			}
			return true;
		}
	}
}