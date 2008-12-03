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

		private var _map:IMap;

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
			var ret:ISet = new Set();
			var len:int = init.length;
			for(var i:int = 0; i < len; i ++){
				var o:Object  = init[i];
				ret = ret.add(o);
			}
			return Set(ret);
		}

		public function Set(){
			_map = RT.map();
		}

		public function toString():String {
			return "<set: " + count() + " items>";
		}

		override public function equals(obj:*):Boolean{
			if(obj == this){
				return true;
			}

			if(!(obj is ISet)){
				return false;
			}
			var m:ISet = ISet(obj);

			if(m.count() != count()){
				return false;
			}

			var ret:Boolean = true;
			_map.each(function(key:*, val:*):void{
					if(!m.contains(key)){
						ret = false;
					}
				});
			return ret;
		}

		public function count():int{
			return _map.count();
		}

		public function contains(obj:Object):Boolean{
			return _map.containsKey(obj);
		}

		public function cons(obj:Object):ISet{
			return add(obj);
		}

		public function add(obj:Object):ISet{
			var s:Set = new Set();
			s._map = _map.assoc(obj, obj);
			return s;
		}

		public function remove(obj:Object):ISet{
			var s:Set = new Set();
			s._map = _map.without(obj);
			return s;
		}

		public function union(s:ISet):ISet{
			var ret:ISet = new Set();
			each(function(ea:Object):void{ 
					ret = ret.add(ea); 
				})
			s.each(function(ea:Object):void{ 
					ret = ret.add(ea); 
				})
			return ret;
		}

		public function subtract(s:ISet):ISet{
			var ret:ISet = new Set();
			each(function(ea:Object):void{ if(!s.contains(ea)) ret = ret.add(ea); });
			return ret;
		}

		public function intersect(s:ISet):ISet{
			var ret:ISet = new Set();
			each(function(ea:Object):void{ if(s.contains(ea)) ret = ret.add(ea); });
			return ret;
		}

		public function seq():ISeq{
			return _map.keys();
		}

		public function each(iterator:Function):void{
			_map.each(function(key:*, val:*):void{
					iterator(key);
				});
		}

		public function reduce(f:Function, start:Object):Object {
			return IReduce(seq()).reduce(f, start);
		}

	}
}

