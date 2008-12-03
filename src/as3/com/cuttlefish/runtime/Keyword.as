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

	public class Keyword implements IHashable{

		public var sym:Symbol;
		private var hash:String;

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
			this.hash = ":" + this.sym.hashCode;
		}

		public function hashCode():*{
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

	}
}

class Lock {}