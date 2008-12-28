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

	public /*abstract*/ class APersistentVector extends AFn implements IVector{
		private var _hash:int = -1;

		public function APersistentVector(meta:IMap = null){
			super(meta);
		}

		public function count():int{
			throw new Error("SubclassResponsibility");
			return null;
		}

		public function pop():IVector{
			throw new Error("SubclassResponsibility");
			return null;
		}

		public function cons(o:Object):IVector{
			throw new Error("SubclassResponsibility");
			return null;
		}

		public function seq():ISeq{
			if(count() > 0)
			return new Seq(this, 0);
			return null;
		}

		public function rseq():ISeq{
			if(count() > 0)
			return new RSeq(this, count() - 1);
			return null;
		}

		public function nth(i:int):Object{
			throw new Error("SubclassResponsibility");
			return null;
		}
		
		public function assocN(i:int, val:Object):IVector{
			throw new Error("SubclassResponsibility");
			return null;
		}

		override public function equals(obj:*):Boolean{
			if(obj === this){ return true;}
			if(obj is IVector){
				var v:IVector = IVector(obj);
				if(count() != v.count()) return false;
				for(var i:int = 0; i < count(); i++)
				{
					if(!Util.equal(nth(i), v.nth(i))) return false;
				}
			}
			else{
				return false;
			}
			return true;
		}

		override public function hashCode():int{
			if(_hash == -1)
			{
				var hash:int = 1;
				for(var i:int = 0; i < count(); i++)
				{
					hash = Util.hashCombine(hash, Util.hash(nth(i)));
				}
				this._hash = hash;
			}
			return _hash;
		}

		public function get(index:int):Object{
			return nth(index);
		}

		public function indexOf(o:Object):int{
			var len:int = count();
			for(var i:int = 0; i < len; i++)
			if(Util.equal(nth(i), o))
			return i;
			return -1;
		}

		public function lastIndexOf(o:Object):int{
			var len:int = count();
			for(var i:int = len - 1; i >= 0; i--)
			if(Util.equal(nth(i), o))
			return i;
			return -1;
		}

		public function peek():Object{
			if(count() > 0)
			return nth(count() - 1);
			return null;
		}

		public function containsKey(key:Object):Boolean{
			if(!key is Number)
			return false;
			var i:int = int(key);
			return i >= 0 && i < count();
		}

		public function entryAt(key:Object):MapEntry{
			if(key is Number)
			{
				var i:int = int(key);
				if(i >= 0 && i < count())
				return new MapEntry(key, nth(i));
			}
			return null;
		}

		public function assoc(key:Object, val:Object):IVector{
			if(key is Number)
			{
				var i:int = int(key);
				return assocN(i, val);
			}
			throw new Error("IllegalArgumentException: Key must be integer");
		}

		public function valAt(key:Object, notFound:Object = null):Object{
			if(key is Number)
			{
				var i:int = int(key);
				if(i >= 0 && i < count())
				return nth(i);
			}
			return notFound;
		}

		public function toArray():Array{
			var source:Array = [];
			for(var c:ISeq = seq(); c != null; c = c.rest()){
				source.push(c.first());
			}
			return source;
		}

		public function size():int{
			return count();
		}

		public function isEmpty():Boolean{
			return count() == 0;
		}

		public function contains(o:Object):Boolean{
			for(var s:ISeq = seq(); s != null; s = s.rest())
			{
				if(Util.equal(s.first(), o))
				return true;
			}
			return false;
		}

		public function length():int{
			return count();
		}

		public function each(iterator:Function):void{
			for(var s:ISeq = seq(); s != null; s = s.rest())
			{
				iterator(s.first());
			}
		}

		public function collect(iterator:Function):IVector{
			var v:IVector = PersistentVector.empty();
			for(var s:ISeq = seq(); s != null; s = s.rest())
			{
				v = v.cons(iterator(s.first()));
			}
			return v;
		}

		public function subvec(start:int, end:int):IVector{
			return new SubVector(this, start, end, meta);
		}

		override public function invoke1(arg1:Object):Object{
			if(arg1 is int)
			return nth(int(arg1));
			throw new Error("IllegalArgumentException: Key must be integer");
		}

	}
}


import com.las3r.runtime.*;

class Seq extends ASeq implements IReduce{
	//todo - something more efficient
	private var v:IVector;
	private var i:int;


	public function Seq(v:IVector, i:int, meta:IMap = null){
		super(meta);
		this.v = v;
		this.i = i;
	}

	override public function first():Object{
		return v.nth(i);
	}

	override public function rest():ISeq{
		if(i + 1 < v.count())
		return new Seq(v, i + 1);
		return null;
	}

	public function index():int{
		return i;
	}

	override public function count():int{
		return v.count() - i;
	}

	override public function withMeta(meta:IMap):IObj{
		return new Seq(v, i, meta);
	}

	override public function reduce(f:Function, start:Object):Object{
		var ret:Object = f(start, v.nth(i));
		var len:int = v.count();
		for(var x:int = i + 1; x < len; x++)
		ret = f(ret, v.nth(x));
		return ret;
	}
}

class RSeq extends ASeq {
	private var v:IVector;
	private var i:int;

	public function RSeq(vector:IVector, i:int, meta:IMap = null){
		super(meta);
		this.v = vector;
		this.i = i;
	}

	override public function first():Object{
		return v.nth(i);
	}

	override public function rest():ISeq{
		if(i > 0)
		return new RSeq(v, i - 1);
		return null;
	}

	public function index():int{
		return i;
	}

	override public function count():int{
		return i + 1;
	}

	override public function withMeta(meta:IMap):IObj{
		return new RSeq(v, i, meta);
	}
}

class SubVector extends APersistentVector{
	private var v:IVector;
	private var start:int;
	private var end:int;


	public function SubVector(v:IVector, start:int, end:int, meta:IMap = null){
		super(meta);
		this.v = v;
		this.start = start;
		this.end = end;
	}

	override public function nth(i:int):Object{
		if(start + i >= end)
		throw new Error("IndexOutOfBoundsException");
		return v.nth(start + i);
	}

	override public function assocN(i:int, val:Object):IVector{
		if(start + i > end)
		throw new Error("IndexOutOfBoundsException");
		else if(start + i == end)
		return cons(val);
		return new SubVector(v.assocN(start + i, val), start, end, meta);
	}

	override public function count():int{
		return end - start;
	}

	override public function cons(o:Object):IVector{
		return new SubVector(v.assocN(end, o), start, end + 1, meta);
	}


	override public function pop():IVector{
		if(end - 1 == start)
		{
			return PersistentVector.empty();
		}
		return new SubVector(v, start, end - 1, meta);
	}

	override public function withMeta(meta:IMap):IObj{
		if(meta == _meta)
		return this;
		return new SubVector(v, start, end, meta);
	}
}