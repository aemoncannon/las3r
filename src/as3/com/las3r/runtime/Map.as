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

	public class Map extends Obj implements IMap{

		private var _dict:Dictionary;

		public static function createFromMany(...init:Array):Map{
			return createFromArray(init);
		}

		public static function createFromArray(init:Array):Map{
			var ret:Map = new Map();
			var len:int = init.length;
			for(var i:int = 0; i < len; i += 2){
				var key:Object  = init[i];				
				if((i + 1) >= len){
					throw new Error("IllegalArgumentException: No value supplied for key: " + key);
				}
				var val:Object  = init[i + 1];
				ret.assoc(key, val);
			}
			return ret;
		}

		public function Map(){
			_dict = new Dictionary();
		}

		public function toString():String {
			return "<map: - " + count() + " items>";
		}

		public function equals(obj:Object):Boolean{
			if(!(obj is IMap))
			return false;
			var m:IMap = IMap(obj);

			if(m.count() != count())
			return false;

			for(var s:ISeq = seq(); s != null; s = s.rest())
			{
				var pair:IVector = IVector(s.first());
				var e:* = pair.nth(1);
				var me:* = m.valAt(pair.nth(0));
				if(me == null || !Util.equal(e, me))
				return false;
			}

			return true;
		}

		public function count():int{
			var i:int = 0;
			for(var key:* in _dict){ i++; }
			return i;
		}

		public function valAt(key:Object, notFound:Object = null):Object{
			var e:* = _dict[key];
			if(e != null)
			return e;
			return notFound;
		}

		public function containsKey(key:Object):Boolean{
			var e:* = _dict[key];
			return e != null;
		}

		public function cons(o:Object):IMap{
			if(o is IVector)
			{
				var v:IVector = IVector(o);
				if(v.count() != 2)
				throw new Error("IllegalArgumentException: Vector arg to map conj must be a pair");
				return assoc(v.nth(0), v.nth(1));
			}

			var ret:IMap = this;
			for(var es:ISeq = RT.seq(o); es != null; es = es.rest())
			{
				var pair:IVector = IVector(es.first());
				ret = ret.assoc(pair.nth(0), pair.nth(1));
			}
			return ret;
		}

		public function assoc(key:Object, val:Object):IMap{
			_dict[key] = val;
			return this;
		}

		public function remove(key:Object):IMap{
			delete _dict[key];
			return this;
		}

		public function seq():ISeq{
			//TODO This is too slow
			var keys:Array = [];
			for(var key:* in _dict){ keys.push(key); }
			return new MapSeq(this, keys, 0);
		}

		public function each(iterator:Function):void{
			for(var key:* in _dict){ iterator(key, _dict[key]); }
		}

	}
}

import com.las3r.runtime.*;

class MapSeq extends ASeq implements ISeq{
	private var m:IMap;
	private var keys:Array;
	private var i:int;

	public function MapSeq(m:IMap, keys:Array, i:int){
		this.m = m;
		this.keys = keys;
		this.i = i;
	}

	override public function first():Object{
		return Vector.createFromArray([keys[i], m.valAt(keys[i])]);
	}

	override public function rest():ISeq{
		if(i + 1 < keys.length)
		return new MapSeq(m, keys, i + 1);
		return null;
	}

	public function index():int{
		return i;
	}

	override public function count():int{
		return keys.length - i;
	}

	public function reduce(f:Function, start:Object = null):Object {
		var st:Object = start || first();
		var ret:Object = f(st, m.valAt(keys[i]));
		for(var x:int = i + 1; x < m.count(); x++){
			ret = f(ret, m.valAt(keys[x]));
		}
		return ret;
	}
}
