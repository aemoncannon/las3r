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

	public class Cons extends ASeq{

		private var _first:Object;
		private var _rest:ISeq;

		public function Cons(first:Object, rest:ISeq){
			_first = first;
			_rest = rest;
		}

		override public function withMeta(meta:IMap):IObj{
			var c:Cons = new Cons(_first, _rest);
			c._meta = meta;
			return c;
		}


		override public function first():Object{
			return _first;
		}

		override public function rest():ISeq{
			return _rest;
		}

		override public function count():int{
			return 1 + RT.count(_rest);
		}

		override public function seq():ISeq{
			return this;
		}

	}
}