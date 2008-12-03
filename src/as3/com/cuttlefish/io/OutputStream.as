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

	public class OutputStream{

		private var _writerFunc:Function;
		
		public function OutputStream(writerFunc:Function = null) {
			_writerFunc = writerFunc || function(str:String):void{};
		}

		public function write(str:String):void{
			_writerFunc(str);
		}

		public function writeOne(ch:int):void{
			write(String.fromCharCode(ch));
		}

	}

}