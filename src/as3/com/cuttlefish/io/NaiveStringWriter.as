/*   
* Copyright (c) Aemon Cannon. All rights reserved.
* The use and distribution terms for this software are covered by the
* Common Public License 1.0 (http://opensource.org/licenses/cpl.php)
* which can be found in the file CPL.TXT at the root of this distribution.
* By using this software in any fashion, you are agreeing to be bound by
* the terms of this license.
* You must not remove this notice, or any other, from this software.
*/


package com.cuttlefish.io{

	/* A temporary class to use as a substitute for a real, java-style
    *  writer/StringWriter implementation
    */
	public class NaiveStringWriter extends OutputStream{

		private var _buf:Array = [];
		
		public function NaiveStringWriter() {
			super(null)
		}

		override public function write(str:String):void{
			_buf.push(str);
		}

		public function toString():String{
			return _buf.join("");
		}

	}


}