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


package com.cuttlefish.util{

	import com.cuttlefish.runtime.IHashable;

	public class Util{

		static public function equal(k1:Object, k2:Object):Boolean{
			if(k1 === k2)
			return true;
			if(k1 === null || k1 is Number || k1 is Boolean || k1 is String)
			return false;
			if(k1.equals){
				return k1.equals(k2);
			}
			return false;
		}

		static public function compare(k1:Object, k2:Object):int{
			if(k1 == k2)
			return 0;
			if(k1 != null)
			{
				if(k2 == null)
				return 1;
				if(k1 is Number && k2 is Number){
					if(k1 < k2) return -1;
					if(k1 > k2) return 1;
					return 0;
				}
				return k1.compareTo(k2);
			}
			return -1;
		}

		static public function hash(o:*):*{
			if(o == null){
				return 0;
			}
			else if(o is String || o is Number || o is Boolean || !(o is Object)){
				return o;
			}
			else if(o is IHashable){
				return o.hashCode();
			}
			else{
				throw o + " is not hashable."
			}
		}

		static public function hashCombine(seed:int, hash:int):int{
			//a la boost
			seed ^= hash + 0x9e3779b9 + (seed << 6) + (seed >> 2);
			return seed;
		}

	}
}