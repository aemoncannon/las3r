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
	
	import mx.collections.ArrayCollection;
	import mx.collections.IViewCursor;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.logging.ILogger;
	import mx.logging.Log;
	
	import org.pranaframework.utils.Assert;
	
	/**
	 * Collection that is forced to hold values of a certain type.
	 * 
	 * @author Christophe Herreman
	 * @author Bert Vandamme
	 */
	public class TypedCollection extends ArrayCollection {
		
		private static var _logger:ILogger = Log.getLogger("org.pranaframework.collections.TypedCollection");
		
		private var _type:Class;
		
		/**
		 * 
		 */
		public function TypedCollection(type:Class, source:Array = null) {
			Assert.notNull(type, "The type argument must not be null");
			_type = type;
			if (source) this.source = source;
			addEventListener(CollectionEvent.COLLECTION_CHANGE, onCollectionChange);
		}
		
		public function get type():Class {
			return _type;
		}
		
		override public function addItem(item:Object):void {
			check(item);
			super.addItem(item);
		}
		
		override public function addItemAt(item:Object, index:int):void {
			check(item);
			super.addItemAt(item, index);
		}
		
		override public function createCursor():IViewCursor {
			return new TypedCollectionViewCursor(_type, super.createCursor());
		}
		
		/**
		 * Removes an item from the TypedCollection
		 * 
		 * @param item the item to be removed from the TypedCollection
		 * 
		 * @return a boolean indicating the succes of the operation
		 */
		public function removeItem(item:Object):Boolean {
			var result:Boolean = false;		
			var itemIndex:int = getItemIndex(item);
			// only remove an entry that exists in the collection
			// else a RangeError will be thrown else
			if (itemIndex != -1) {
				var removedItem:Object = removeItemAt(itemIndex) as _type;
				result = (removedItem != null);
			}
			return result;
		}
		
		/**
		 * Checks if the passed item is of the object type of the TypedCollection
		 * 
		 * @param item the object to be checked
		 */
		private function check(item:Object):void {
			if (!(item is _type)) {
				throw new TypeError("Wrong type, " + _type.toString() + " was expected");
			}
		}
		
		/**
		 * Registers an ITypedCollectionListener listener
		 * 
		 * @param listener the event listener
		 */
		public function addListener(listener:ITypedCollectionListener):void {
			addEventListener(TypedCollectionEvent.ADD, listener.onTypedCollectionItemAdd);
		}
		
		/**
		 * Handles the COLLECTION_CHANGE event
		 */
		private function onCollectionChange(event:CollectionEvent):void {
			switch(event.kind) {
				case CollectionEventKind.ADD:
					for(var i:int=0; i<event.items.length; i++){
						var item:Object = event.items[i];
						dispatchEvent(new TypedCollectionEvent(TypedCollectionEvent.ADD, item));	
					}
				break;
			}
		}
		
	}
}