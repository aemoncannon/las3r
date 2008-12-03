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

package com.cuttlefish.runtime{

	import flash.utils.Dictionary;
	import com.cuttlefish.util.Util;
	import com.cuttlefish.jdk.util.ArrayUtil;


	public class PersistentArrayMap extends APersistentMap{

		private var array:Array;
		public static var EMPTY:PersistentArrayMap = new PersistentArrayMap();

		public function PersistentArrayMap(init:Array = null, meta:IMap = null){
			this.array = init || [];
			_meta = meta;
		}

		override public function withMeta(meta:IMap):IObj{
			return new PersistentArrayMap(array, meta);
		}


		override public function count():int{
			return array.length / 2;
		}

		override public function containsKey(key:Object):Boolean{
			return indexOf(key) >= 0;
		}

		override public function entryAt(key:Object):MapEntry{
			var i:int = indexOf(key);
			if(i >= 0)
			return new MapEntry(key, array[i+1]);
			return null;
		}

		override public function assoc(key:Object, val:Object):IMap {
			var i:int = indexOf(key);
			var newArray:Array = [];
			if(i >= 0) //already have key, same-sized replacement
			{
				if(array[i + 1] == val) //no change, no op
				return this;
				newArray = new Array(this.array);
				newArray[i + 1] = val;
			}
			else //didn't have key, grow
			{
				newArray = new Array(array.length + 2);
				if(array.length > 0)
				ArrayUtil.arraycopy(array, 0, newArray, 2, array.length);
				newArray[0] = key;
				newArray[1] = val;
			}
			return new PersistentArrayMap(newArray);
		}

		override public function without(key:Object):IMap{
			var i:int = indexOf(key);
			if(i >= 0) //have key, will remove
			{
				var newlen:int = array.length - 2;
				if(newlen == 0)
				return empty();
				var newArray:Array = new Array(newlen);
				for(var s:int = 0, d = 0; s < array.length; s += 2)
				{
					if(!equalKey(array[s], key)) //skip removal key
					{
						newArray[d] = array[s];
						newArray[d + 1] = array[s + 1];
						d += 2;
					}
				}
				return new PersistentArrayMap(newArray);
			}
			//don't have key, no op
			return this;
		}

		public function empty():IMap{
			return IMap(EMPTY.withMeta(meta));
		}

		override public function valAt(key:Object, notFound:Object = null):Object{
			var i:int = indexOf(key);
			if(i >= 0)
			return array[i + 1];
			return notFound;
		}

		public function capacity():int{
			return count();
		}

		private function indexOf(key:Object):int{
			for(var i:int = 0; i < array.length; i += 2)
			{
				if(equalKey(array[i], key))
				return i;
			}
			return -1;
		}

		private function equalKey(k1:Object, k2:Object):Boolean{
			if(k1 == null)
			return k2 == null;
			return Util.equal(k1, k2);
		}

		override public function seq():ISeq {
			if(array.length > 0)
			return new Seq(array, 0, meta);
			return null;
		}

	}

}

import com.cuttlefish.runtime.MapEntry;
import com.cuttlefish.runtime.ASeq;
import com.cuttlefish.runtime.ISeq;
import com.cuttlefish.runtime.IMap;
import com.cuttlefish.runtime.Obj;
import com.cuttlefish.runtime.IObj;


class Seq extends ASeq{
	private var array:Array;
	private var i:int;

	public function Seq(array:Array, i:int, meta:IMap = null){
		super(meta);
		this.array = array;
		this.i = i;
	}

	override public function first():Object{
		return new MapEntry(array[i],array[i+1]);
	}

	override public function rest():ISeq{
		if(i + 2 < array.length)
		return new Seq(array, i + 2, meta);
		return null;
	}

	override public function count():int{
		return (array.length - i) / 2;
	}

	override public function withMeta(meta:IMap):IObj{
		return new Seq(array, i, meta);
	}
}
