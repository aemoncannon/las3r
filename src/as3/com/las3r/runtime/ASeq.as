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

	public class ASeq extends Obj implements ISeq, IReduce{
		private var _hash:int = -1;

		public function empty():ISeq{
			return null;
		}

		public function ASeq(meta:IMap = null){
			super(meta);
		}

		override public function equals(obj:*):Boolean{
			if(!(obj is ISeq)) return false;
			var ms:ISeq = ISeq(obj);
			for(var s:ISeq = seq(); s != null; s = s.rest(), ms = ms.rest())
			{
				if(ms == null || !Util.equal(s.first(), ms.first()))
				return false;
			}
			if(ms != null)
			return false;
			return true;
		}

		override public function hashCode():int{
			if(_hash == -1)
			{
				var hash:int = 0;
				for(var s:ISeq = seq(); s != null; s = s.rest())
				{
					hash = Util.hashCombine(hash, Util.hash(s.first()));
				}
				this._hash = hash;
			}
			return _hash;
		}

		public function reduce(f:Function, start:Object):Object{
			var ret:Object = f(start, first());
			for(var s:ISeq = rest(); s != null; s = s.rest()){
				ret = f(ret, s.first());
			}
			return ret;
		}


		public function count():int{
			var i:int = 1;
			for(var s:ISeq = rest(); s != null; s = s.rest(), i++){}
			return i;
		}

		public function seq():ISeq{
			return this;
		}

		public function cons(o:Object):ISeq{
			return new Cons(o, this);
		}

		public function first():Object{
			throw new Error("Subclass responsibility, 'first'")
		}

		public function rest():ISeq{
			throw new Error("Subclass responsibility, 'rest'")
		}


	}
}