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

	public class Vector extends PersistentVector{

		public static var EMPTY:PersistentVector = new Vector(0, 5, [], []);

		static public function createFromSeq(items:ISeq):IVector{
			var ret:IVector = EMPTY;
			for(; items != null; items = items.rest())
			ret = ret.cons(items.first());
			return ret;
		}

		static public function createFromArray(items:Array):IVector{
			var ret:IVector = EMPTY;
			for(var item:* in items)
			ret = ret.cons(item);
			return ret;
		}

		public static function createFromArraySlice(items:Array, i:int):IVector{
			return createFromArray(items.slice(i));
		}

		public static function createFromMany(...items:Array):IVector{
			return createFromArray(items);
		}

		public function Vector(cnt:int, shift:int, root:Array, tail:Array, meta:IMap = null){
			super(cnt, shift, root, tail, meta);
		}

	}

}


