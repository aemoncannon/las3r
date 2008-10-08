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

	public class StringSeq extends ASeq implements ISeq, IReduce{
		//todo - something more efficient
		private var str:String;
		private var i:int;

		public function StringSeq(str:String, i:int){
			this.str = str;
			this.i = i;
		}

		override public function first():Object{
			return str.charAt(i);
		}

		override public function rest():ISeq{
			if(i + 1 < str.length)
			return new StringSeq(str, i + 1);
			return null;
		}

		public function index():int{
			return i;
		}

		override public function count():int{
			return str.length - i;
		}

		override public function reduce(f:Function, start:Object):Object {
			var ret:Object = f(start, str.charAt(i));
			for(var x:int = i + 1; x < str.length; x++){
				ret = f(ret, str.charAt(x));
			}
			return ret;
		}
	}
}