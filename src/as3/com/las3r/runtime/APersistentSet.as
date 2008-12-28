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

	public /*abstract*/ class APersistentSet extends AFn implements ISet{
		private var _hash:int = -1;
		protected var impl:IMap;

		public function APersistentSet(impl:IMap, meta:IMap = null){
			super(meta);
			this.impl = impl;
		}

		public function contains(key:Object):Boolean{
			return impl.containsKey(key);
		}

		public function get(key:Object):Object{
			return impl.valAt(key);
		}

		public function count():int{
			return impl.count();
		}

		public function seq():ISeq {
			return RT.keys(impl);
		}

		override public function equals(obj:*):Boolean{
			if(!(obj is APersistentSet))
			return false;
			var m:APersistentSet = APersistentSet(obj);

			if(m.count() != count() || m.hashCode() != hashCode())
			return false;

			for(var s:ISeq = seq(); s != null; s = s.rest())
			{
				if(!m.contains(s.first()))
				return false;
			}

			return true;
		}

		override public function hashCode():int{
			if(_hash == -1)
			{
				var hash:int = 0;
				for(var s:ISeq = seq(); s != null; s = s.rest())
				{
					var e:Object = s.first();
					hash +=  Util.hash(e);
				}
				this._hash = hash;
			}
			return _hash;
		}

		public function toArray():Array{
			return RT.seqToArray(seq());
		}

		public function isEmpty():Boolean{
			return count() == 0;
		}

		public function each(iterator:Function):void{
			for(var s:ISeq = seq(); s != null; s = s.rest())
			{
				iterator(s.first);
			}
		}

		public function reduce(f:Function, start:Object):Object {
			return IReduce(seq()).reduce(f, start);
		}

		public function add(obj:Object):ISet{
			return cons(obj);
		}

		public function cons(obj:Object):ISet{
			throw new Error("UnsupportedOperationException");
			return null;
		}

		public function disjoin(obj:Object):ISet{
			throw new Error("UnsupportedOperationException");
			return null;
		}

		public function remove(obj:Object):ISet{
			return disjoin(obj);
		}

		override public function withMeta(meta:IMap):IObj{
			throw new Error("UnsupportedOperationException");
			return null;
		}

		protected function empty():ISet{
			throw new Error("UnsupportedOperationException");
			return null;
		}

		public function union(s:ISet):ISet{
			var ret:ISet = this.empty();
			each(function(ea:Object):void{ 
					ret = ret.add(ea); 
				})
			s.each(function(ea:Object):void{ 
					ret = ret.add(ea); 
				})
			return ret;
		}

		public function subtract(s:ISet):ISet{
			var ret:ISet = this.empty();
			each(function(ea:Object):void{ if(!s.contains(ea)) ret = ret.add(ea); });
			return ret;
		}

		public function intersect(s:ISet):ISet{
			var ret:ISet = this.empty();
			each(function(ea:Object):void{ if(s.contains(ea)) ret = ret.add(ea); });
			return ret;
		}

		override public function invoke1(arg1:Object):Object{
			return get(arg1);
		}


	}
}
