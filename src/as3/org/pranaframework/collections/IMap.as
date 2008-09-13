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
 package org.pranaframework.collections {
	
	/**
	 * An object that contains key/value pairs. It cannot contain duplicate keys
	 * and each key can only contain one correspoding value.
	 * 
	 * @author Christophe Herreman
	 * @author Damir Murat
	 */
	public interface IMap {
		
		/**
		 * Removes all key/value pairs from the map.
		 */
		function clear():void;
		
		/**
		 * Returns the number of key/value pairs in the map.
		 * 
		 * @return the number of key/value pairs in the map
		 */
		function get size():uint;
		
		/**
		 * Returns an array of all values in the map. If no values exist in
		 * the map, then an empty Array instance will be returned.
		 * 
		 * @return an array of all values in the map
		 */
		function get values():Array;
		
		/**
		 * Adds an object to the map and associates it with the specified key.
		 */
		function put(key:Object, value:Object):void;
		
		/**
		 * Returns the value in the map associated with the specified key.
		 */
		function get(key:Object):*;
		
		/**
		 * Removes the mapping for this key from this map if it is present.
		 * 
		 * Returns the value to which the map previously associated the key,
		 * or null if the map contained no mapping for this key.
		 * (A null return can also indicate that the map previously associated
		 * null with the specified key if the implementation supports null
		 * values.) The map will not contain a mapping for the specified key
		 * once the call returns.
		 * 
		 * @param key the key whose mapping is to be removed from the map
		 * @return previous value associated with specified key, or null if
		 * there was no mapping for key
		 */
		function remove(key:Object):*;
	}
}