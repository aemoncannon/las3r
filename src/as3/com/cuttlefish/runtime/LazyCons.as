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

package com.cuttlefish.runtime{

	import com.cuttlefish.util.Util;

	public class LazyCons extends ASeq{

		private static var sentinel:ISeq = new Cons(null, null);
		public var f:Function;
		private var _first:Object;
		private var _rest:ISeq;

		public function LazyCons(f:Function = null, first:Object = null, rest:ISeq = null){
			this.f = f;
			this._first = first || sentinel;
			this._rest = rest || sentinel;
		}


	    override public function first():Object{
			if(_first == sentinel)
		    {
				_first = f();
		    }
			return _first;
	    }


	    override public function rest():ISeq{
			if(_rest == sentinel)
		    {
				//force sequential evaluation
				if(_first == sentinel){
					first();
				}
				_rest = RT.seq(f(null));
				f = null;
		    }
			return _rest;
	    }


		override public function withMeta(meta:IMap):IObj{
			if(meta == this.meta)
			return this;
			//force before copying
			rest();

			var l:LazyCons = new LazyCons(null, _first, _rest);
			l._meta = meta;
			return l;
		}
	}

}
