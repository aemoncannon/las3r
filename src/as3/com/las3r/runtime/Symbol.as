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

	import com.las3r.util.StringUtil;
	import com.las3r.runtime.RT;

    public class Symbol extends Obj{

		//these must be interned strings!
		public var ns:String;
		public var name:String;

		public function toString():String{
			if(ns != null)
			return ns + "/" + name;
			return name;
		}

		public function getNamespace():String{
			return ns;
		}

		public function getName():String{
			return name;
		}

		public static function intern2(rt:RT, ns:String, name:String):Symbol{
			var s:Symbol = new Symbol(ns == null ? null : StringUtil.intern(rt, ns), StringUtil.intern(rt, name), new Lock());
			var key:String = s.toString();
			var existing:Symbol = rt.internedSymbols[key];
			if(existing){
				return existing;
			}
			else{
				rt.internedSymbols[key] = s;
				return s;
			}
		}

		public static function intern1(rt:RT, nsname:String):Symbol{
			var i:int= nsname.indexOf('/');
			if(i == -1){
				return intern2(rt, null, StringUtil.intern(rt, nsname));
			}
			else{
				return intern2(rt, StringUtil.intern(rt, nsname.substring(0, i)), StringUtil.intern(rt, nsname.substring(i + 1)));
			}
		}

		public function Symbol(nsInterned:String, nameInterned:String, l:Lock){
			super(null);
			this.name = nameInterned;
			this.ns = nsInterned;
		}

		override public function withMeta(meta:IMap):IObj{
			var s:Symbol = this;//new Symbol(ns, name, new Lock());
			s._meta = meta;
			return s;
		}

		public function equals(o:Object):Boolean{
			if(this == o)
			return true;

			if(!(o is Symbol))
			return false;

			var symbol:Symbol = Symbol(o);
			return name == symbol.name && ns == symbol.ns;
		}

		public function compareTo(o:Object):int{
			var s:Symbol= Symbol(o);

			if(this.equals(o))
			return 0;

			if(this.ns == null && s.ns != null)
			return -1;

			if(this.ns != null){
				if(s.ns == null)
				return 1;
				var nsc:int= this.ns.localeCompare(s.ns);
				if(nsc != 0)
				return nsc;
			}
			return this.name.localeCompare(s.name);
		}




    }
}

class Lock {}