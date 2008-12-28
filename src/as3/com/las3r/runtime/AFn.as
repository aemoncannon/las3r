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
	import com.las3r.util.*;

	public /*abstract*/ class AFn extends Obj implements IFn{

		public function AFn(meta:IMap = null){ super(meta); }

		override public function withMeta(meta:IMap):IObj{
			throw new Error("UnsupportedOperationException");;
		}

		public function call():Object{
			return invoke0();
		}

		public function invoke0() :Object{
			return throwArity();
		}

		public function invoke1(args1:Object) :Object{
			return throwArity();
		}

		public function invoke2(args1:Object, args2:Object) :Object{
			return throwArity();
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
			return applyToHelper(this, arglist);
		}

		static public function applyToHelper(ifn:IFn, arglist:ISeq):Object{
			switch(RT.boundedLength(arglist, 20))
			{
				case 0:
				return ifn.invoke0();
				case 1:
				return ifn.invoke1(arglist.first());
				case 2:
				return ifn.invoke2(arglist.first()
					, (arglist = arglist.rest()).first()
				);
				case 3:
				return ifn.invoke3(arglist.first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
				);
				case 4:
				return ifn.invoke4(arglist.first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
				);
				case 5:
				return ifn.invoke5(arglist.first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
				);
				case 6:
				return ifn.invoke6(arglist.first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
				);
				case 7:
				return ifn.invoke7(arglist.first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
				);
				case 8:
				return ifn.invoke8(arglist.first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
				);
				case 9:
				return ifn.invoke9(arglist.first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
				);
				case 10:
				return ifn.invoke10(arglist.first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
				);
				case 11:
				return ifn.invoke11(arglist.first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
				);
				case 12:
				return ifn.invoke12(arglist.first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
				);
				case 13:
				return ifn.invoke13(arglist.first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
				);
				case 14:
				return ifn.invoke14(arglist.first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
				);
				case 15:
				return ifn.invoke15(arglist.first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
				);
				case 16:
				return ifn.invoke16(arglist.first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
				);
				case 17:
				return ifn.invoke17(arglist.first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
				);
				case 18:
				return ifn.invoke18(arglist.first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
				);
				case 19:
				return ifn.invoke19(arglist.first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
				);
				case 20:
				return ifn.invoke20(arglist.first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
					, (arglist = arglist.rest()).first()
				);
				default:
				var name:String = RT.nameForInstanceClass(ifn);
				throw new Error("IllegalArgumentException: Wrong number of args passed to: " + name);
			}
		}

		public function throwArity():Object{
			var name:String = RT.nameForInstanceClass(this);
			throw new Error("IllegalArgumentException: Wrong number of args passed to: " + name);
		}

	}

}