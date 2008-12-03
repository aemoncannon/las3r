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

package com.cuttlefish.io{

	import com.cuttlefish.jdk.io.*;

	public class LineNumberingPushbackReader extends PushbackReader{

		public function LineNumberingPushbackReader(r:Reader, size:int = 2){
			super(new LineNumberReader(r), size);
		}

		public function getLineNumber():int{
			return LineNumberReader(_in).getLineNumber() + 1;
		}

		public function readLine():String{
			return LineNumberReader(_in).readLine();
		}
	}
}