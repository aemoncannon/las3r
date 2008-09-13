/**
*   Copyright (c) Rich Hickey. All rights reserved.
*   The use and distribution terms for this software are covered by the
*   Common Public License 1.0 (http://opensource.org/licenses/cpl.php)
*   which can be found in the file CPL.TXT at the root of this distribution.
*   By using this software in any fashion, you are agreeing to be bound by
* 	 the terms of this license.
*   You must not remove this notice, or any other, from this software.
**/


package com.las3r.util{

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
			}
			return -1;
		}

	}
}