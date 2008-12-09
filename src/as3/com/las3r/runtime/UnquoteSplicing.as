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
	import com.las3r.runtime.*;
	import com.las3r.io.*;
	import com.las3r.util.*;

	public class UnquoteSplicing implements IHashable{
		public var o:Object;

		public function UnquoteSplicing(o:Object){
			this.o = o;
		}

		public function equals(obj:Object):Boolean{
			return obj is UnquoteSplicing && o.equals(obj.o);
		}

		public function hashCode():int{
			return Util.hash(o);
		}
	}


}