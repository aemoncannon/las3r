/**
*   Copyright (c) Rich Hickey. All rights reserved.
*   Copyright (c) Aemon Cannon. All rights reserved.
*   The use and distribution terms for this software are covered by the
*   Eclipse Public License 1.0 (http://opensource.org/licenses/eclipse-1.0.php)
*   which can be found in the file epl-v10.html at the root of this distribution.
*   By using this software in any fashion, you are agreeing to be bound by
* 	 the terms of this license.
*   You must not remove this notice, or any other, from this software.
**/

package com.las3r.runtime{

	import com.las3r.util.Util;
	import com.las3r.jdk.util.ArrayUtil;


	public class PersistentStructMap extends APersistentMap{

		private var def:StructMapDef;
		private var values:Array;
		private var ext:IMap;

		public static function createSlotMap(keys:ISeq):StructMapDef{
			if(keys == null)
			throw new Error("IllegalArgumentException: Must supply keys");
			var ret:PersistentHashMap = PersistentHashMap.empty();
			var i:int = 0;
			for(var s:ISeq = keys; s != null; s = s.rest(), i++)
			{
				ret = PersistentHashMap(ret.assoc(s.first(), i));
			}
			return new StructMapDef(keys, ret);
		}

		public static function create(def:StructMapDef, keyvals:ISeq):PersistentStructMap{
			var values:Array = new Array(def.keyslots.count());
			var ext:IMap = PersistentHashMap.empty();
			for(; keyvals != null; keyvals = keyvals.rest().rest())
			{
				if(keyvals.rest() == null)
				throw new Error("IllegalArgumentException: No value supplied for key: " + keyvals.first());
				var k:Object = keyvals.first();
				var v:Object = RT.second(keyvals);
				var e:MapEntry = def.keyslots.entryAt(k);

				if(e != null)
				values[int(e.value)] = v;
				else
				ext = ext.assoc(k, v);
			}
			return new PersistentStructMap(def, values, ext);
		}

		public static function construct(def:StructMapDef, valseq:ISeq):PersistentStructMap{
			var values:Array = new Array(def.keyslots.count());
			var ext:IMap = PersistentHashMap.empty();
			for(var i:int = 0; i < values.length && valseq != null; valseq = valseq.rest(), i++)
			{
				values[i] = valseq.first();
			}
			if(valseq != null)
			throw new Error("IllegalArgumentException: Too many arguments to struct constructor");
			return new PersistentStructMap(def, values, ext);
		}

		public static function getAccessor(def:StructMapDef, key:Object):Function{
			var e:MapEntry = def.keyslots.entryAt(key);
			if(e != null)
			{
				var i:int = int(e.value);
				return function(arg1:Object):Object{
					var m:PersistentStructMap = PersistentStructMap(arg1);
					if(m.def != def)
					throw new Error("Exception: Accessor/struct mismatch");
					return m.values[i];
				};
			}
			throw new Error("IllegalArgumentException: Not a key of struct");
		}

		public function PersistentStructMap(def:StructMapDef , values:Array, ext:IMap, meta:IMap = null){
			super(meta);
			this.ext = ext;
			this.def = def;
			this.values = values;
		}

		/**
		* Returns a new instance of PersistentStructMap using the given parameters.
		* This function is used instead of the PersistentStructMap constructor by
		* all methods that return a new PersistentStructMap.  This is done so as to
		* allow subclasses to return instances of their class from all
		* PersistentStructMap methods.
		*/
		protected function makeNew(def:StructMapDef, values:Array, ext:IMap, meta:IMap = null):PersistentStructMap{
			return new PersistentStructMap(def, values, ext, meta);
		}

		override public function withMeta(meta:IMap):IObj{
			if(meta == _meta)
			return this;
			return makeNew(def, values, ext, meta);
		}

		override public function containsKey(key:Object):Boolean{
			return def.keyslots.containsKey(key) || ext.containsKey(key);
		}

		override public function entryAt(key:Object):MapEntry{
			var e:MapEntry = def.keyslots.entryAt(key);
			if(e != null)
			{
				return new MapEntry(key, values[int(e.value)]);
			}
			return ext.entryAt(key);
		}

		override public function assoc(key:Object, val:Object):IMap{
			var e:MapEntry = def.keyslots.entryAt(key);
			if(e != null)
			{
				var i:int = int(e.value);
				var newVals:Array = ArrayUtil.clone(values);
				newVals[i] = val;
				return makeNew(def, newVals, ext, _meta);
			}
			return makeNew(def, values, ext.assoc(key, val), _meta);
		}

		override public function valAt(key:Object, notFound:Object = null):Object{
			var e:MapEntry = def.keyslots.entryAt(key);
			if(e != null)
			{
				return values[int(e.value)];
			}
			return ext.valAt(key, notFound);
		}

		public function assocEx(key:Object, val:Object):IMap{
			if(containsKey(key))
			throw new Error("Key already present");
			return assoc(key, val);
		}

		override public function without(key:Object):IMap{
			var e:MapEntry = def.keyslots.entryAt(key);
			if(e != null)
			throw new Error("Can't remove struct key");
			var newExt:IMap = ext.without(key);
			if(newExt == ext)
			return this;
			return makeNew(def, values, newExt, _meta);
		}

		override public function count():int{
			return values.length + RT.count(ext);
		}

		override public function seq():ISeq{
			return new Seq(def.keys, values, 0, ext, null);
		}

	}
}

import com.las3r.runtime.*;

class Seq extends ASeq{
	private var i:int;
	private var keys:ISeq;
	private var values:Array;
	private var ext:IMap;


	public function Seq(keys:ISeq, values:Array, i:int, ext:IMap, meta:IMap){
		super(meta);
		this.i = i;
		this.keys = keys;
		this.values = values;
		this.ext = ext;
	}

	override public function withMeta(meta:IMap):IObj{
		if(meta != _meta)
		return new Seq(keys, values, i, ext, meta);
		return this;
	}

	override public function first():Object{
		return new MapEntry(keys.first(), values[i]);
	}

	override public function rest():ISeq{
		if(i + 1 < values.length)
		return new Seq(keys.rest(), values, i + 1, ext, _meta);
		return ext.seq();
	}
}


