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

	import com.las3r.util.Util;

	public /*abstract*/ class APersistentMap extends Obj implements IMap, IReduce{

		private var _hash:int = -1;

		public function APersistentMap(meta:IMap = null){
			super(meta);
		}

		public function toString():String{
			return "<map: - " + count() + " items>";
		}

		public function cons(o:Object):IMap {
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

			var ret:IMap  = this;
			for(var es:ISeq  = RT.seq(o); es != null; es = es.rest())
			{
				var me:MapEntry = MapEntry(es.first());
				ret = ret.assoc(me.key, me.value);
			}
			return ret;
		}


		override public function equals(obj:*):Boolean {
			if(!(obj is APersistentMap))
			return false;

			var m:APersistentMap = APersistentMap(obj);

			if(m.count() != count() || m.hashCode() != hashCode())
			return false;

			for(var s:ISeq = seq(); s != null; s = s.rest())
			{
				var e:MapEntry = MapEntry(s.first());
				var me:MapEntry = m.entryAt(e.key);
				if(me == null || !Util.equal(e.value, me.value))
				return false;
			}

			return true;
		}

		override public function hashCode():int{
			if(_hash == -1)
			{
				var hash:int = count();
				for(var s:ISeq = seq(); s != null; s = s.rest())
				{
					var e:MapEntry = MapEntry(s.first());
					hash ^= Util.hashCombine(Util.hash(e.key), Util.hash(e.value));
				}
				this._hash = hash;
			}
			return _hash;
		}

		public function contains(o:Object):Boolean{
			if(o is MapEntry)
			{
				var e:MapEntry = MapEntry(o);
				var v:MapEntry = MapEntry(entryAt(e.key));
				return (v != null && Util.equal(v.value, e.value));
			}
			return false;
		}

		public function valAt(key:Object, notFound:Object = null):Object{ throw "subclass responsibility"; return null }

		public function entryAt(key:Object):MapEntry{ throw "subclass responsibility"; return null;}

		public function assoc(key:Object, val:Object):IMap{ throw "subclass responsibility"; return null; }

		public function without(key:Object):IMap{ throw "subclass responsibility"; return null; }

		public function count():int{ throw "subclass responsibility"; return null; }

		public function seq():ISeq{ throw "subclass responsibility"; return null; }

		public function keys():ISeq{ return KeySeq.create(seq()); }

		public function vals():ISeq{ return ValSeq.create(seq()); }

		public function each(iterator:Function):void{
			for(var s:ISeq = seq(); s != null; s = s.rest())
			{
				var e:MapEntry = MapEntry(s.first());
				iterator(e.key, e.value);
			}
		}

		public function containsKey(key:Object):Boolean{ 
			return entryAt(key) != null; 
		}


		public function reduce(f:Function, start:Object):Object{
			var seq:ISeq = seq();
			var ret:Object = f(start, seq.first());
			for(var s:ISeq = seq.rest(); s != null; s = s.rest()){
				ret = f(ret, s.first());
			}
			return ret;
		}

	}
}

import com.las3r.runtime.MapEntry;
import com.las3r.runtime.ASeq;
import com.las3r.runtime.ISeq;
import com.las3r.runtime.IMap;
import com.las3r.runtime.Obj;
import com.las3r.runtime.IObj;


class KeySeq extends ASeq{
	private var _seq:ISeq;

	static public function create(seq:ISeq):KeySeq{
		if(seq == null)
		return null;
		return new KeySeq(seq);
	}

	public function KeySeq(seq:ISeq, meta:IMap = null){
		super(meta)
		_seq = seq;
	}

	override public function first():Object{
		return MapEntry(_seq.first()).key;
	}

	override public function rest():ISeq{
		return create(_seq.rest());
	}

	override public function withMeta(meta:IMap):IObj{
		return new KeySeq(_seq, meta);
	}
}

class ValSeq extends ASeq{
	private var _seq:ISeq;

	static public function create(seq:ISeq):ValSeq{
		if(seq == null)
		return null;
		return new ValSeq(seq);
	}

	public function ValSeq(seq:ISeq, meta:IMap = null){
		super(meta)
		_seq = seq;
	}

	override public function first():Object{
		return MapEntry(_seq.first()).value;
	}

	override public function rest():ISeq{
		return create(_seq.rest());
	}

	override public function withMeta(meta:IMap):IObj{
		return new ValSeq(_seq, meta);
	}
}




