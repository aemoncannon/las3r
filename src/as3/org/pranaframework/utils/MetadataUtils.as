/**
 * Copyright (c) 2007-2008, the original author(s)
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *		 * Redistributions of source code must retain the above copyright notice,
 *			 this list of conditions and the following disclaimer.
 *		 * Redistributions in binary form must reproduce the above copyright
 *			 notice, this list of conditions and the following disclaimer in the
 *			 documentation and/or other materials provided with the distribution.
 *		 * Neither the name of the Prana Framework nor the names of its contributors
 *			 may be used to endorse or promote products derived from this software
 *			 without specific prior written permission.
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
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	/**
	 * This class provides utility methods concerning metadata. Retrieved metadata is cached and cleared with the 
	 * set interval.
	 * 
	 * @see #CLEAR_CACHE_INTERVAL
	 */
	public class MetadataUtils {
		/**
		 * The interval (in miliseconds) at which the cache will be cleared. Note that this value is only used 
		 * on the first call to getFromObject.
		 * 
		 * @default 60000 (one minute)
		 */
		static public var CLEAR_CACHE_INTERVAL:uint = 60000;
		
		static private var _cache:Object = new Object();
		static private var _timer:Timer;
		
		static private function _timerHandler(e:TimerEvent):void {
			clearCache();
		}
		
		/**
		 * Will return the metadata for the given object or class. If metadata has already been requested for 
		 * this type, it will be retrieved from cache. Note that the metadata will allways be that of the class, 
		 * even if you pass an instance.
		 * <p />
		 * In order to get instance specific metadata, use the 'factory' property.
		 * <p />
		 * The reason we do not allow retrieval of instance metadata is because then we would need to cache the 
		 * metadata double. Metadata takes up a significant amount of memory. 
		 * 
		 * @param object	The object from which you want to grab the metadata
		 * 
		 * @return The class metadata of the given object.
		 */
		static public function getFromObject(object:Object):XML {
			var className:String = getQualifiedClassName(object);
			var metadata:XML;
			
			if (_cache.hasOwnProperty(className)) {
				metadata = _cache[className];
			}
			else {
				if (!_timer) {
					/*
						Only run the timer once to prevent unneeded overhead. This also prevents 
						this class from falling for the bug described here:
						
						http://www.gskinner.com/blog/archives/2008/04/failure_to_unlo.html
					*/
					_timer = new Timer(CLEAR_CACHE_INTERVAL, 1);
					_timer.addEventListener(TimerEvent.TIMER, _timerHandler);
				}
				
				if (!(object is Class)) {
					object = object.constructor;
				}
				
				metadata = describeType(object);
				
				_cache[className] = metadata;
				
				if (!_timer.running) {
					/*
						Only run the timer if it is not already running.
					*/
					_timer.start();
				}
			}
			
			return metadata;
		}
		
		/**
		 * Will retrieve the metadata for the given class. Note that in order to access properties and 
		 * methods you need to grab the 'factory' part of the metadata.
		 * 
		 * @param className		The name of the class that you want to retrieve metadata from. The className 
		 * 						may be in the following forms: package.Class or package::Class
		 */
		static public function getFromString(className:String):XML {
			var classDefinition:Class = getDefinitionByName(className) as Class;
			
			/*
				Calling getFromObject seems double, as it results in the getObjectMethod getting 
				the class name using getQualifiedClassName. It however saves us a check on the 
				given className which might be in two forms.
				
				getQualifiedClassName(getDefinitionByName(className)) is faster then converting the 
				string using conventional methods. 
			*/
			return getFromObject(classDefinition);
		}
				
		/**
		 * Allows you to clear the internal cache.
		 */
		static public function clearCache():void {
			_cache = new Object();
			
			if (_timer && _timer.running) {
				_timer.stop();
			}
		}
	}
}