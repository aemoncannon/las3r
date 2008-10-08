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

	public class Map extends Obj implements IMap, IReduce{

		private var _dict:Dictionary;

		public static function createFromMany(...init:Array):Map{
			return createFromArray(init);
		}

		public static function createFromSeq(seq:ISeq):Map{
			var source:Array = [];
			for(var c:ISeq = seq; c != null; c = c.rest()){
				source.push(c.first());
			}
			return createFromArray(source);
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
			if(!(obj is IMap)){
				return false;
			}
			var m:IMap = IMap(obj);

			if(m.count() != count()){
				return false;
			}
			
			for(var key:* in _dict){
				if(!Util.equal(m.valAt(key), valAt(key))){
					return false;
				}
			}
			return true;
		}

		public function count():int{
			var i:int = 0;
			for(var key:* in _dict){ i++; }
			return i;
		}

		public function valAt(key:Object, notFound:Object = null):Object{
			var e:MapEntry = _dict[key];
			if(e != null){
				return e.value;
			}
			return notFound;
		}

		public function entryAt(key:Object):Object{
			return _dict[key];
		}

		public function containsKey(key:Object):Boolean{
			return _dict[key] != null;
		}

		public function cons(o:Object):IMap{
			if(o is MapEntry)
			{
				var e:MapEntry = MapEntry(o);
				return assoc(e.key, e.value);
			}
			else if(o is IVector)
			{
				var v:IVector = IVector(o);
				if(v.count() != 2)
				throw new Error("IllegalArgumentException: Vector arg to map conj must be a pair");
				return assoc(v.nth(0), v.nth(1));
			}

			var ret:IMap = this;
			for(var es:ISeq = RT.seq(o); es != null; es = es.rest())
			{
				var entry:MapEntry = MapEntry(es.first());
				ret = ret.assoc(entry.key, entry.value);
			}
			return ret;
		}

		public function assoc(key:Object, val:Object):IMap{
			_dict[key] = new MapEntry(key, val);
			return this;
		}

		public function remove(key:Object):IMap{
			delete _dict[key];
			return this;
		}

		public function seq():ISeq{
			//TODO This is too slow
			var entries:Array = [];
			for each(var e:MapEntry in _dict){ entries.push(e); }
			if(entries.length > 0){
				return new MapSeq(entries, 0);
			}
			else{
				return null;
			}
		}

		public function each(iterator:Function):void{
			for(var key:* in _dict){ iterator(key, _dict[key].value); }
		}

		public function reduce(f:Function, start:Object):Object {
			return MapSeq(seq()).reduce(f, start);
		}

	}
}

import com.las3r.runtime.*;

class MapSeq extends ASeq implements ISeq{
	private var entries:Array;
	private var i:int;

	public function MapSeq(entries:Array, i:int){
		this.entries = entries;
		this.i = i;
	}

	override public function first():Object{
		return entries[i];
	}

	override public function rest():ISeq{
		if(i + 1 < entries.length)
		return new MapSeq(entries, i + 1);
		return null;
	}

	public function index():int{
		return i;
	}

	override public function count():int{
		return entries.length - i;
	}

	override public function reduce(f:Function, start:Object):Object {
		var ret:Object = f(start, entries[i].value);
		var len:int = count();
		for(var x:int = i + 1; x < len; x++){
			ret = f(ret, entries[x].value);
		}
		return ret;
	}
}
