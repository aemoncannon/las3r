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

	public class Set extends Obj implements ISet, IReduce{

		private var _dict:Dictionary;

		public static function createFromMany(...init:Array):Set{
			return createFromArray(init);
		}

		public static function createFromSeq(seq:ISeq):Set{
			var source:Array = [];
			for(var c:ISeq = seq; c != null; c = c.rest()){
				source.push(c.first());
			}
			return createFromArray(source);
		}

		public static function createFromArray(init:Array):Set{
			var ret:Set = new Set();
			var len:int = init.length;
			for(var i:int = 0; i < len; i ++){
				var o:Object  = init[i];				
				ret.add(o);
			}
			return ret;
		}

		public function Set(){
			_dict = new Dictionary();
		}

		public function toString():String {
			return "<set: " + count() + " items>";
		}

		public function equals(obj:Object):Boolean{
			if(!(obj is ISet)){
				return false;
			}
			var m:ISet = ISet(obj);

			if(m.count() != count()){
				return false;
			}
			
			for(var key:* in _dict){
				if(!m.contains(key)){
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

		public function contains(obj:Object):Boolean{
			return _dict[obj] != null;
		}

		public function add(obj:Object):ISet{
			_dict[obj] = obj;
			return this;
		}

		public function remove(obj:Object):ISet{
			delete _dict[obj];
			return this;
		}

		public function union(s:ISet):ISet{
			var ret:Set = new Set();
			each(function(ea:Object):void{ ret.add(ea); })
			s.each(function(ea:Object):void{ ret.add(ea); })
			return ret;
		}

		public function subtract(s:ISet):ISet{
			var ret:Set = new Set();
			each(function(ea:Object):void{ if(!s.contains(ea)) ret.add(ea); });
			return ret;
		}

		public function intersect(s:ISet):ISet{
			var ret:Set = new Set();
			each(function(ea:Object):void{ if(s.contains(ea)) ret.add(ea); });
			return ret;
		}

		public function seq():ISeq{
			//TODO This is too slow
			var entries:Array = [];
			for each(var obj:Object in _dict){ entries.push(obj); }
			if(entries.length > 0){
				return new SetSeq(entries, 0);
			}
			else{
				return null;
			}
		}

		public function each(iterator:Function):void{
			for(var obj:* in _dict){ iterator(obj); }
		}

		public function reduce(f:Function, start:Object):Object {
			return SetSeq(seq()).reduce(f, start);
		}

	}
}

import com.las3r.runtime.*;

class SetSeq extends ASeq implements ISeq{
	private var entries:Array;
	private var i:int;

	public function SetSeq(entries:Array, i:int){
		this.entries = entries;
		this.i = i;
	}

	override public function withMeta(meta:IMap):IObj{
		var s:SetSeq = new SetSeq(entries, i);
		s._meta = meta;
		return s;
	}

	override public function first():Object{
		return entries[i];
	}

	override public function rest():ISeq{
		if(i + 1 < entries.length)
		return new SetSeq(entries, i + 1);
		return null;
	}

	public function index():int{
		return i;
	}

	override public function count():int{
		return entries.length - i;
	}

	override public function reduce(f:Function, start:Object):Object {
		var ret:Object = f(start, entries[i]);
		var len:int = count();
		for(var x:int = i + 1; x < len; x++){
			ret = f(ret, entries[x]);
		}
		return ret;
	}
}
