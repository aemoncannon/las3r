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


package com.cuttlefish.runtime{
	import com.cuttlefish.runtime.*;
	import com.cuttlefish.io.*;
	import com.cuttlefish.util.*;

	public class Unquote{
		public var o:Object;

		public function Unquote(o:Object){
			this.o = o;
		}

		public function equals(obj:Object):Boolean{
			return obj is Unquote && o.equals(obj.o);
		}
	}


}