/**
* Copyright (c) Rich Hickey. All rights reserved.
* Copyright (c) Aemon Cannon. All rights reserved.
* The use and distribution terms for this software are covered by the
* Common Public License 1.0 (http://opensource.org/licenses/cpl.php)
* which can be found in the file CPL.TXT at the root of this distribution.
* By using this software in any fashion, you are agreeing to be bound by
* the terms of this license.
* You must not remove this notice, or any other, from this software.
*/

package com.las3r.runtime{
	
	public class Range extends ASeq implements IReduce{
		private var end:int;
		private var n:int;

		public function Range(start:int, end:int){
			this.end = end;
			this.n = start;
		}

		override public function withMeta(meta:IMap):IObj{
			var r:Range = new Range(n, end);
			r._meta = meta;
			return r;
		}

		override public function first():Object{
			return n;
		}

		override public function rest():ISeq{
			if(n < end-1)
			return ISeq((new Range(n + 1, end)).withMeta(_meta));
			return null;
		}

		override public function reduce(f:Function, start:Object):Object{
			var ret:Object = f(start,n);
			for(var x:int = n+1; x < end; x++){
				ret = f(ret, x);
			}
			return ret;
		}

	}
}