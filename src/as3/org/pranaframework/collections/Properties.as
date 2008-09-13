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
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import org.pranaframework.utils.StringUtils;
	
	/**
	 * The <code>Properties</code> class represents a collection of properties
	 * in the form of key-value pairs. All keys and values are of type
	 * <code>String</code>
	 * 
	 * @author Christophe Herreman
	 */
	public class Properties extends EventDispatcher {
		
		private var _properties:Object;
		private var _loader:URLLoader;
		
		/**
		 * Creates a new <code>Properties</code> object.
		 */
		public function Properties() {
			super(this);
			_properties = {};
			_loader = new URLLoader();
			_loader.addEventListener(Event.COMPLETE, onLoaderComplete);
			_loader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
		}
		
		/**
		 * Gets the value of property that corresponds to the given <code>key</code>.
		 * If no property was found, <code>null</code> is returned.
		 * 
		 * @param key the name of the property to get
		 * @returns the value of the property with the given key, or null if none was found
		 */
		public function getProperty(key:String):String {
			return _properties[key];
		}
		
		/**
		 * Sets a property. If the property with the given key already exists,
		 * it will be replaced by the new value.
		 * 
		 * @param key the key of the property to set
		 * @param value the value of the property to set
		 */
		public function setProperty(key:String, value:String):void {
			_properties[key] = value;
		}
		
		/**
		 * Returns an array with the keys of all properties. If no properties
		 * were found, an empty array is returned.
		 * 
		 * @return an array with all keys
		 */
		public function get propertyNames():Array {
			var result:Array = [];
			for (var key:String in _properties) {
				result.push(key);
			}
			return result;
		}
		
		/**
		 * Loads a collection of properties from an external file.
		 * Each property must be on a new line and in the form <i>key</i>=
		 * <i>value</i>.
		 * All keys and values are trimmed. Blank lines that do not contain
		 * properties are ignored. When the loading (and parsing) is done, a 
		 * Event.COMPLETE event is dispatched.
		 * 
		 * @param url the url of the properties file
		 */
		public function load(url:String):void {
			var request:URLRequest = new URLRequest(url);
			_loader.load(request);
		}
		
		private function onLoaderComplete(event:Event):void {
			var stringData:String = _loader.data as String;
			var rawProperties:Array = stringData.split("\r\n");
			
			for (var i:int = 0; i<rawProperties.length; i++) {
				var rawProperty:String = StringUtils.trim(rawProperties[i]);
				if ("" != rawProperty) {
					var propertyParts:Array = rawProperties[i].split("=");
					if (2 == propertyParts.length) {
						setProperty(StringUtils.trim(propertyParts[0]), 
									StringUtils.trim(propertyParts[1]));
					}
				}
			}
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		private function onIOError(event:IOErrorEvent):void {
			dispatchEvent(event);
		}

	}
}