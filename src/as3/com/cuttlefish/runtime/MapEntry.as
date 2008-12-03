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

	import com.cuttlefish.util.Util;

	public class MapEntry{

		public var key:*;
		public var value:*;

		public function MapEntry(key:*, value:*){
			this.key = key;
			this.value = value;
		}

		public function equals(obj:Object):Boolean{
			if(obj == this){
				return true;
			}
			else if(!(obj is MapEntry)){
				return false;
			}
			else{
				return Util.equal(obj.key, key) && Util.equal(obj.value, value);
			}
		}

	}
}
