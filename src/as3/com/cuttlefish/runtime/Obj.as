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
	/*abstract*/ public class Obj implements IObj, IHashable{
		protected var _meta:IMap;

		public function Obj(meta:IMap = null){
			this._meta = meta;
		}

		public function get meta():IMap{
			return _meta;
		}

		public function withMeta(meta:IMap):IObj{ 
			throw "Subclass responsibility";
			return null;
		}

		public function hashCode():*{
			throw "Subclass responsibility. " + this + " is not hashable.";
			return -1;
		}

		public function equals(o:*):Boolean{
			return o === this;
		}


	}
}