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
	import com.las3r.jdk.util.ArrayUtil;

	public class ArraySeq extends ASeq implements IReduce{
		private var array:Array;
		private var i:int;

		public static function createFromArray(array:Array):ISeq{
			if(array == null || array.length == 0)
			return null;
			return new ArraySeq(array, 0);
		}

		public function ArraySeq(array:Array, i:int, meta:IMap = null){
			super(meta);
			this.array = array;
			this.i = i;
		}

		override public function first():Object{
			return array[i];
		}

		override public function rest():ISeq{
			if(i + 1 < array.length)
			return new ArraySeq(array, i + 1);
			return null;
		}

		override public function count():int{
			return array.length - i;
		}

		public function index():int{
			return i;
		}

		override public function withMeta(meta:IMap):IObj{
			return new ArraySeq(array, i, meta);
		}

		override public function reduce(f:Function, start:Object):Object{
			var ret:Object = f(start, array[i]);
			for(var x:int = i + 1; x < array.length; x++)
			ret = f(ret, array[x]);
			return ret;
		}


	}
}