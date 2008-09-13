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
	
	import org.pranaframework.utils.Assert;
	
	import flash.events.EventDispatcher;
	
	import mx.collections.CursorBookmark;
	import mx.collections.ICollectionView;
	import mx.collections.IViewCursor;
	import mx.logging.Log;
	import mx.logging.ILogger;
	import mx.collections.ArrayCollection;
	
	
	[Event(name="cursorUpdate", type="mx.events.FlexEvent")]
	
	/**
	 * Map view cursor.
	 * 
	 * @author Christophe Herreman
	 * @author Bert Vandamme
	 */
	public class MapViewCursor extends EventDispatcher implements IViewCursor {
		
		private static var _logger:ILogger = Log.getLogger("org.pranaframework.collections.MapViewCursor");
		
		private var _view:IMap;
		//private var _arrayCollection:ArrayCollection;
		private var _cursor:IViewCursor;
		
		/**
		 *
		 */
		public function MapViewCursor(view:IMap) {
			super(this);
			_view = view;
			_cursor = new ArrayCollection(view.values).createCursor();
		}
		
     	[Bindable("cursorUpdate")]
		public function get afterLast():Boolean {
			return _cursor.afterLast;
		}
		
	    [Bindable("cursorUpdate")]
	    public function get beforeFirst():Boolean {
	    	return _cursor.beforeFirst;
	    }

	    [Bindable("cursorUpdate")]
	    public function get bookmark():CursorBookmark {
	    	return _cursor.bookmark;
	    }
	
	    [Bindable("cursorUpdate")]
	    public function get current():Object {
			return _cursor.current;
	    }
	
	    public function get view():ICollectionView {
	    	return _cursor.view;
	    }
	
	    public function findAny(values:Object):Boolean {
	    	return _cursor.findAny(values);
	    }
	
	    public function findFirst(values:Object):Boolean {
	    	return _cursor.findFirst(values);
	    }
	
	    public function findLast(values:Object):Boolean {
	    	return _cursor.findLast(values);
	    }
	
	    public function insert(item:Object):void {
	    	_cursor.insert(item);
	    }
	
	    public function moveNext():Boolean {
	    	return _cursor.moveNext();
	    }
	
	    public function movePrevious():Boolean {
	    	return _cursor.movePrevious();
	    }
	
	    public function remove():Object {
	    	return _cursor.remove();
	    }
	
	    public function seek(bookmark:CursorBookmark, offset:int = 0, prefetch:int = 0):void {
	    	_cursor.seek(bookmark, offset, prefetch);
	    }
		
	}
}