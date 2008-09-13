/**
*   Copyright (c) Rich Hickey. All rights reserved.
*   The use and distribution terms for this software are covered by the
*   Common Public License 1.0 (http://opensource.org/licenses/cpl.php)
*   which can be found in the file CPL.TXT at the root of this distribution.
*   By using this software in any fashion, you are agreeing to be bound by
* 	 the terms of this license.
*   You must not remove this notice, or any other, from this software.
**/

package com.las3r.runtime{

	public class List extends ASeq implements IList{

		private var _first:Object;
		private var _rest:List;
		private var _count:int;

		private static var _empty:EmptyList;
		public static function get EMPTY():EmptyList{
			_empty = _empty || new EmptyList();
			return _empty;
		}

		public function List(first:Object, rest:List = null, count:int = 1){
			_first = first;
			_rest = rest;
			_count = count;
		}

		public static function createFromArray(init:Array):List{
			var ret:ISeq = ISeq(EMPTY);
			var len:int = init.length;
			for(var i:int = len - 1; i > -1; i--){
				ret = ISeq(ret.cons(init[i]));
			}
			return List(ret);
		}

		override public function first():Object{
			return _first;
		}

		override public function rest():ISeq{
			if(_count == 1)
			return null;
			return ISeq(_rest);
		}

		public function peek():Object{
			return first();
		}

		override public function count():int{
			return _count;
		}

		override public function cons(o:Object):ISeq{
			return new List(o, this, _count + 1);
		}

		override public function empty():ISeq{
			return EMPTY;	
		}

		public function reduce(f:Function, start:Object = null):Object{
			var st:Object = start || first();
			var ret:Object = f(st, first());
			for(var s:ISeq = rest(); s != null; s = s.rest()){
				ret = f(ret, s.first());
			}
			return ret;
		}

		
	}
}

import com.las3r.runtime.*;

class EmptyList extends Obj implements ISeq, IList{

	public function cons(o:Object):ISeq{
		return new List(o, null, 1);
	}

	public function empty():ISeq{
		return this;
	}

	public function peek():Object{
		return null;
	}

	public function first():Object{
		throw new Error("IllegalStateException: Can't get first from empty list");
	}

	public function rest():ISeq{
		throw new Error("IllegalStateException: Can't get rest from empty list");
	}

	public function count():int{
		return 0;
	}

	public function seq():ISeq{
		return null;
	}
}
