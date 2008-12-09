/**
*   Copyright (c) Rich Hickey. All rights reserved.
*   Copyright (c) Aemon Cannon. All rights reserved.
*   The use and distribution terms for this software are covered by the
*   Common Public License 1.0 (http://opensource.org/licenses/cpl.php)
*   which can be found in the file CPL.TXT at the root of this distribution.
*   By using this software in any fashion, you are agreeing to be bound by
* 	 the terms of this license.
*   You must not remove this notice, or any other, from this software.
**/

package com.las3r.runtime{

	import flash.utils.Dictionary;
	import com.las3r.util.Util;

	public class PersistentHashSet extends APersistentSet{

		private static var _empty:PersistentHashSet;
		public static function empty():PersistentHashSet {
			_empty = _empty || new PersistentHashSet(PersistentHashMap.empty());
			return _empty;
		}

		public static function createFromMany(...init:Array):PersistentHashSet{
			return createFromArray(init);
		}

		public static function createFromSeq(seq:ISeq):PersistentHashSet{
			var ret:ISet = empty()
			for(var c:ISeq = seq; c != null; c = c.rest()){
				ret = ret.add(c.first());
			}
			return PersistentHashSet(ret);
		}

		public static function createFromArray(init:Array):PersistentHashSet{
			var ret:ISet = empty();
			var len:int = init.length;
			for(var i:int = 0; i < len; i ++){
				var o:Object  = init[i];
				ret = ret.add(o);
			}
			return PersistentHashSet(ret);
		}

		public function PersistentHashSet(impl:IMap, meta:IMap = null){
			super(impl, meta);
		}

		override public function disjoin(key:Object):ISet{
			if(contains(key))
			return new PersistentHashSet(impl.without(key), meta);
			return this;
		}

		override public function cons(o:Object):ISet{
			if(contains(o))
			return this;
			return new PersistentHashSet(impl.assoc(o,o), meta);
		}

		override public function withMeta(meta:IMap):IObj{
			return new PersistentHashSet(impl, meta);
		}

		override protected function empty():ISet{
			throw new Error("UnsupportedOperationException");
			return null;
		}



	}
}