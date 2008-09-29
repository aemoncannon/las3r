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

	dynamic public class Vector extends Array implements IVector, IObj, IReduce{

		protected var _meta:IMap;

		public function get meta():IMap{
			return _meta;
		}

		public function withMeta(meta:IMap):IObj{
			_meta = meta;
			return this;
		}

		static function doEquals(v:IVector, obj:Object):Boolean{
			if(obj is IVector){
				var ma:IVector = IVector(obj);
				if(ma.count() != v.count()){
					return false;
				}
				for(var i:int = 0; i < v.count(); i++)
				{
					if(!Util.equal(v.nth(i), ma.nth(i)))
					return false;
				}
				return true;
			}
			return false;
		}

		public function each(iterator:Function):void{
			for each(var ea:Object in this){ iterator(ea); }
		}

		public function collect(iterator:Function):IVector{
			var v:IVector = Vector.empty();
			for each(var ea:Object in this){ v.cons(iterator(ea)); }
			return v;
		}

		public function equals(obj:Object):Boolean{
			return doEquals(this, obj);
		}

		public static function createFromSeq(seq:ISeq):Vector{
			var source:Array = [];
			for(var c:ISeq = seq; c != null; c = c.rest()){
				source.push(c.first());
			}
			return createFromArray(source);
		}

		public static function createFromArray(items:Array):Vector{
			return new Vector(items);
		}

		public static function createFromArraySlice(items:Array, i:int):Vector{
			return new Vector(items.slice(i));
		}

		public static function createFromMany(...items:Array):Vector{
			return createFromArray(items);
		}

		public static function empty():Vector{
			return new Vector([]);
		}

		public function Vector(source:Array){
			for each(var ea:Object in source){
				push(ea);
			}
		}

		public function peek():Object{
			if(count() > 0)
			return nth(count() - 1);
			return null;
		}


		public function popEnd():Object{
			return super.pop();
		}


		public function invoke1(arg1:Object):Object{
			return nth(int(arg1));
		}

		public function nth(i:int):Object{
			return this[i]
		}

		public function assocN(i:int, val:Object):IVector{
			this[i] = val;
			return this;
		}

		public function count():int{
			return this.length;
		}

		public function cons(val:Object):IVector{
			this.push(val);
			return this;
		}

		public function empty():Vector{
			return new Vector([]);
		}

		public function seq():ISeq{
			if(count() > 0)
			return new VectorSeq(this, 0);
			return null;
		}

		public function reduce(f:Function, start:Object):Object {
			return VectorSeq(seq()).reduce(f, start);
		}

		public function includes(obj:Object):Boolean{
			return indexOf(obj) > -1;
		}

	}

}


import com.las3r.runtime.*;

class VectorSeq extends ASeq implements ISeq{
	//todo - something more efficient
	private var v:IVector;
	private var i:int;

	public function VectorSeq(v:IVector, i:int){
		this.v = v;
		this.i = i;
	}

	override public function first():Object{
		return v.nth(i);
	}

	override public function rest():ISeq{
		if(i + 1 < v.count())
		return new VectorSeq(v, i + 1);
		return null;
	}

	public function index():int{
		return i;
	}

	override public function count():int{
		return v.count() - i;
	}

	override public function reduce(f:Function, start:Object):Object {
		var ret:Object = f(start, v.nth(i));
		for(var x:int = i + 1; x < v.count(); x++){
			ret = f(ret, v.nth(x));
		}
		return ret;
	}
}
