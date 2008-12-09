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
	import com.las3r.jdk.util.ArrayUtil;

	public class PersistentVector extends APersistentVector{
		private var cnt:int;
		private var shift:int;
		private var root:Array;
		private var tail:Array;

		public static var EMPTY:PersistentVector = new PersistentVector(0, 5, [], []);

		static public function createFromSeq(items:ISeq):PersistentVector{
			var ret:PersistentVector = EMPTY;
			for(; items != null; items = items.rest())
			ret = PersistentVector(ret.cons(items.first()));
			return ret;
		}

		static public function createFromArray(items:Array):PersistentVector{
			var ret:PersistentVector = EMPTY;
			for each(var item:* in items)
			ret = PersistentVector(ret.cons(item));
			return ret;
		}

		public static function createFromArraySlice(items:Array, i:int):PersistentVector{
			return createFromArray(items.slice(i));
		}

		public static function createFromMany(...items:Array):PersistentVector{
			return createFromArray(items);
		}

		public function PersistentVector(cnt:int, shift:int, root:Array, tail:Array, meta:IMap = null){
			super(meta);
			this.cnt = cnt;
			this.shift = shift;
			this.root = root;
			this.tail = tail;
		}

		public function tailoff():int{
			return cnt - tail.length;
		}

		override public function nth(i:int):Object{
			if(i >= 0 && i < cnt)
			{
				if(i >= tailoff())
				return tail[i & 0x01f];
				var arr:Array = root;
				for(var level:int = shift; level > 0; level -= 5)
				arr = arr[(i >>> level) & 0x01f];
				return arr[i & 0x01f];
			}
			throw new Error("IndexOutOfBoundsException");
		}

		override public function assocN(i:int, val:Object):IVector{
			if(i >= 0 && i < cnt)
			{
				if(i >= tailoff())
				{
					var newTail:Array = ArrayUtil.clone(tail);
					newTail[i & 0x01f] = val;
					return new PersistentVector(cnt, shift, root, newTail, meta);
				}
				return new PersistentVector(cnt, shift, doAssoc(shift, root, i, val), tail, meta);
			}
			if(i == cnt)
			return cons(val);
			throw new Error("IndexOutOfBoundsException");
		}

		private static function doAssoc(level:int, arr:Array, i:int, val:Object):Array{
			var ret:Array = ArrayUtil.clone(arr);
			if(level == 0)
			{
				ret[i & 0x01f] = val;
			}
			else
			{
				var subidx:int = (i >>> level) & 0x01f;
				ret[subidx] = doAssoc(level - 5, arr[subidx], i, val);
			}
			return ret;
		}

		override public function count():int{
			return cnt;
		}

		override public function withMeta(meta:IMap):IObj{
			return new PersistentVector(cnt, shift, root, tail, meta);
		}


		override public function cons(val:Object):IVector{
			if(tail.length < 32)
			{
				var newTail:Array = new Array(tail.length + 1);
				ArrayUtil.arraycopy(tail, 0, newTail, 0, tail.length);
				newTail[tail.length] = val;
				return new PersistentVector(cnt + 1, shift, root, newTail, meta);
			}
			var expansion:Box = new Box(null);
			var newroot:Array = pushTail(shift - 5, root, tail, expansion);
			var newshift:int = shift;
			if(expansion.val != null)
			{
				newroot = [newroot, expansion.val];
				newshift += 5;
			}
			return new PersistentVector(cnt + 1, newshift, newroot, [val], meta);
		}

		private function pushTail(level:int, arr:Array, tailNode:Array, expansion:Box):Array{
			var newchild:Object;
			if(level == 0)
			{
				newchild = tailNode;
			}
			else
			{
				newchild = pushTail(level - 5, arr[arr.length - 1], tailNode, expansion);
				if(expansion.val == null)
				{
					var ret:Array = ArrayUtil.clone(arr);
					ret[arr.length - 1] = newchild;
					return ret;
				}
				else
				newchild = expansion.val;
			}
			//expansion
			if(arr.length == 32)
			{
				expansion.val = [newchild];
				return arr;
			}
			ret = new Array(arr.length + 1);
			ArrayUtil.arraycopy(arr, 0, ret, 0, arr.length);
			ret[arr.length] = newchild;
			expansion.val = null;
			return ret;
		}

		override public function pop():IVector{
			if(cnt == 0)
			throw new Error("IllegalStateException: Can't pop empty vector");
			if(cnt == 1)
			return IVector(IObj(empty()).withMeta(meta));
			if(tail.length > 1)
			{
				var newTail:Array = new Array(tail.length - 1);
				ArrayUtil.arraycopy(tail, 0, newTail, 0, newTail.length);
				return new PersistentVector(cnt - 1, shift, root, newTail, meta);
			}
			var ptail:Box = new Box(null);
			var newroot:Array = popTail(shift - 5, root, ptail);
			var newshift:int = shift;
			if(newroot == null)
			{
				newroot = [];
			}
			if(shift > 5 && newroot.length == 1)
			{
				newroot = newroot[0];
				newshift -= 5;
			}
			return new PersistentVector(cnt - 1, newshift, newroot, ptail.val, meta);
		}

		private function popTail(shift:int, arr:Array, ptail:Box):Array{
			if(shift > 0)
			{
				var newchild:Array = popTail(shift - 5, arr[arr.length - 1], ptail);
				if(newchild != null)
				{
					var ret:Array = ArrayUtil.clone(arr);
					ret[arr.length - 1] = newchild;
					return ret;
				}
			}
			if(shift == 0)
			ptail.val = arr[arr.length - 1];
			//contraction
			if(arr.length == 1)
			return null;
			ret = new Array(arr.length - 1);
			ArrayUtil.arraycopy(arr, 0, ret, 0, ret.length);
			return ret;
		}

	}
}
