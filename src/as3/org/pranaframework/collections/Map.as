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
	import flash.utils.Dictionary;
	
	import mx.collections.ICollectionView;
	import mx.collections.IViewCursor;
	import mx.collections.Sort;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	
	[Event(name="collectionChange", type="mx.events.CollectionEvent")]
	
	/**
	 * Basic implementation of the IMap interface.
	 * 
	 * @author Christophe Herreman
	 */
	dynamic public class Map extends Dictionary implements IMap, ICollectionView {
		
		private var _eventDispatcher:EventDispatcher;
		
		/**
		 * Constructs a new <code>Map</code> instance.
		 */
		public function Map() {
			_eventDispatcher = new EventDispatcher(this);
		}
		
		//---------------------------------------------------------------------
		// IMap implementation
		//---------------------------------------------------------------------
		public function clear():void {
			for (var key:* in this) {
				delete this[key];
			}
		}
		
		public function get size():uint {
			var result:uint = 0;
			for (var key:* in this) {
				result++;
			}
			return result;
		}
		
		public function get values():Array {
			var result:Array = new Array();
			for each (var value:* in this) {
				result.push(value);
			}
			return result;
		}
		
		public function put(key:Object, value:Object):void {
			this[key] = value;
		}
		
		[Bindable("collectionChange")]
		public function get(key:Object):* {
			return this[key];
		}
		
		/**
		 * @inheritDoc
		 */
		public function remove(key:Object):* {
			var result:* = get(key);
			delete this[key];
			return result;
		}
		
		public function toString():String {
			var result:String = "[Map(";
			for (var p:String in this) {
				result += p + ": " + this[p] + ", ";
			}
			//result = result.substr(0, result.length-2);
			result += ")]";
			return result;
		}
		
		//---------------------------------------------------------------------
		// ICollectionView implementation
		//---------------------------------------------------------------------
		public function get length():int {
			return size;
		}
		
		private var _filterFunction:Function;
		public function get filterFunction():Function {
			return _filterFunction;
		}
		public function set filterFunction(value:Function):void {
			_filterFunction = value;
		}
		
		private var _sort:Sort;
		public function get sort():Sort {
			return _sort;
		}
    	public function set sort(value:Sort):void {
    		_sort = value;
    	}
    	
    	public function createCursor():IViewCursor {
    		return new MapViewCursor(this);
    	}
    	
    	public function contains(item:Object):Boolean {
    		return (get(item) != null);
    	}
    	
    	public function disableAutoUpdate():void {
    	
    	}

		public function enableAutoUpdate():void {
			
		}
		
		public function itemUpdated(item:Object, property:Object = null,
                         oldValue:Object = null, newValue:Object = null):void {
		
		}
		
		// TODO
		public function refresh():Boolean {
			return false;
		}
		
		//---------------------------------------------------------------------
		// IEventDispatcher implementation
		//---------------------------------------------------------------------
		public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void {
			_eventDispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference); 
		}
		
		public function dispatchEvent(event:Event):Boolean {
			return _eventDispatcher.dispatchEvent(event);
		}
		
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void {
			_eventDispatcher.removeEventListener(type, listener, useCapture);
		}
		
		public function hasEventListener(type:String):Boolean {
			return _eventDispatcher.hasEventListener(type);
		}
		
		public function willTrigger(type:String):Boolean {
			return _eventDispatcher.willTrigger(type);
		}
		//---------------------------------------------------------------------
	}
}