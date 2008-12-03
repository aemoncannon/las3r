/**
* Copyright (c) Aemon Cannon. All rights reserved.
* The use and distribution terms for this software are covered by the
* Common Public License 1.0 (http://opensource.org/licenses/cpl.php)
* which can be found in the file CPL.TXT at the root of this distribution.
* By using this software in any fashion, you are agreeing to be bound by
* the terms of this license.
* You must not remove this notice, or any other, from this software.
*/


package com.las3r.util
{

	import flash.utils.ByteArray;

	public class StringBuffer{

		private var _pieces:Array = [];
		private var _length:int = 0;
		
		public function append(str:String):StringBuffer{
			_pieces.push(str);
			_length += str.length;
			return this;
		}

		public function appendBytesFromArray(buffer:Array, i:int, j:int):StringBuffer{
			var byteArray:ByteArray = new ByteArray();
			for(var index:int = i; i < j; index++){
				byteArray.writeByte(buffer[index]);
			}
			var str:String = byteArray.readUTFBytes(byteArray.length);
			return append(str);
		}

		public function length():int{
			return _length;
		}

		public function toString():String{
			return _pieces.join("");
		}

		public function clear():void{
			_length = 0;
			_pieces = [];
		}
		
	}

}
