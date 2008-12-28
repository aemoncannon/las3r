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

	public class Keyword implements IFn, IHashable{

		public var sym:Symbol;
		private var hash:int;

		public static function intern1(rt:RT, sym:Symbol):Keyword{
			var k:Keyword = rt.internedKeywords[sym];
			if(k){
				return k;
			}
			else{
				k = new Keyword(sym, new Lock);
				rt.internedKeywords[sym] = k;
				return k;
			}
		}

		public static function intern2(rt:RT, ns:String, name:String):Keyword{
			return intern1(rt, Symbol.intern2(rt, ns, name));
		}

		public function Keyword(sym:Symbol, l:Lock){
			this.sym = sym;
			this.hash = Util.hashCombine(Util.stringHash(":"), this.sym.hashCode());
		}

		public function hashCode():int{
			return this.hash;
		}

		public function equals(o:*):Boolean{
			if(this == o)
			return true;

			if(!(o is Keyword))
			return false;
			
			var k:Keyword = Keyword(o);
			return k.sym.equals(this.sym);
		}

		public function toString():String{
			return ":" + sym.toString();
		}

		public function compareTo(o:Object):int{
			return sym.compareTo((Keyword(o)).sym);
		}

		public function getNamespace():String{
			return sym.getNamespace();
		}

		public function getName():String{
			return sym.getName();
		}


		public function throwArity():Object{
			throw new Error("IllegalArgumentException: Wrong number of args passed to keyword: " + toString());
		}

		public function call():Object{
			return invoke0();
		}

		public function invoke0():Object{
			return throwArity();
		}

		/**
		* Indexer implements IFn for attr access
		*
		* @param obj - must be IMap
		* @return the value at the key or nil if not found
		*/
		public function invoke1(obj:Object) :Object{
			return RT.get(obj, this);
		}

		public function invoke2(obj:Object, notFound:Object) :Object{
			return RT.get(obj, this, notFound);
		}

		public function invoke3(args1:Object, args2:Object, args3:Object) :Object{
			return throwArity();
		}

		public function invoke4(args1:Object, args2:Object, args3:Object, args4:Object) :Object{
			return throwArity();
		}

		public function invoke5(args1:Object, args2:Object, args3:Object, args4:Object, args5:Object) :Object{
			return throwArity();
		}

		public function invoke6(args1:Object, args2:Object, args3:Object, args4:Object, args5:Object, args6:Object) :Object{
			return throwArity();
		}

		public function invoke7(args1:Object, args2:Object, args3:Object, args4:Object, args5:Object, args6:Object, args7:Object)
		:Object{
			return throwArity();
		}

		public function invoke8(args1:Object, args2:Object, args3:Object, args4:Object, args5:Object, args6:Object, args7:Object,
            args8:Object) :Object{
			return throwArity();
		}

		public function invoke9(args1:Object, args2:Object, args3:Object, args4:Object, args5:Object, args6:Object, args7:Object,
            args8:Object, args9:Object) :Object{
			return throwArity();
		}

		public function invoke10(args1:Object, args2:Object, args3:Object, args4:Object, args5:Object, args6:Object, args7:Object,
            args8:Object, args9:Object, args10:Object) :Object{
			return throwArity();
		}

		public function invoke11(args1:Object, args2:Object, args3:Object, args4:Object, args5:Object, args6:Object, args7:Object,
            args8:Object, args9:Object, args10:Object, args11:Object) :Object{
			return throwArity();
		}

		public function invoke12(args1:Object, args2:Object, args3:Object, args4:Object, args5:Object, args6:Object, args7:Object,
            args8:Object, args9:Object, args10:Object, args11:Object, args12:Object) :Object{
			return throwArity();
		}

		public function invoke13(args1:Object, args2:Object, args3:Object, args4:Object, args5:Object, args6:Object, args7:Object,
            args8:Object, args9:Object, args10:Object, args11:Object, args12:Object, args13:Object)
		:Object{
			return throwArity();
		}

		public function invoke14(args1:Object, args2:Object, args3:Object, args4:Object, args5:Object, args6:Object, args7:Object,
            args8:Object, args9:Object, args10:Object, args11:Object, args12:Object, args13:Object, args14:Object)
		:Object{
			return throwArity();
		}

		public function invoke15(args1:Object, args2:Object, args3:Object, args4:Object, args5:Object, args6:Object, args7:Object,
            args8:Object, args9:Object, args10:Object, args11:Object, args12:Object, args13:Object, args14:Object,
            args15:Object) :Object{
			return throwArity();
		}

		public function invoke16(args1:Object, args2:Object, args3:Object, args4:Object, args5:Object, args6:Object, args7:Object,
            args8:Object, args9:Object, args10:Object, args11:Object, args12:Object, args13:Object, args14:Object,
            args15:Object, args16:Object) :Object{
			return throwArity();
		}

		public function invoke17(args1:Object, args2:Object, args3:Object, args4:Object, args5:Object, args6:Object, args7:Object,
            args8:Object, args9:Object, args10:Object, args11:Object, args12:Object, args13:Object, args14:Object,
            args15:Object, args16:Object, args17:Object) :Object{
			return throwArity();
		}

		public function invoke18(args1:Object, args2:Object, args3:Object, args4:Object, args5:Object, args6:Object, args7:Object,
            args8:Object, args9:Object, args10:Object, args11:Object, args12:Object, args13:Object, args14:Object,
            args15:Object, args16:Object, args17:Object, args18:Object) :Object{
			return throwArity();
		}

		public function invoke19(args1:Object, args2:Object, args3:Object, args4:Object, args5:Object, args6:Object, args7:Object,
            args8:Object, args9:Object, args10:Object, args11:Object, args12:Object, args13:Object, args14:Object,
            args15:Object, args16:Object, args17:Object, args18:Object, args19:Object) :Object{
			return throwArity();
		}

		public function invoke20(args1:Object, args2:Object, args3:Object, args4:Object, args5:Object, args6:Object, args7:Object,
            args8:Object, args9:Object, args10:Object, args11:Object, args12:Object, args13:Object, args14:Object,
            args15:Object, args16:Object, args17:Object, args18:Object, args19:Object, args20:Object)
		:Object{
			return throwArity();
		}


		public function applyTo(arglist:ISeq) :Object{
			return AFn.applyToHelper(this, arglist);
		}

	}
}

class Lock {}