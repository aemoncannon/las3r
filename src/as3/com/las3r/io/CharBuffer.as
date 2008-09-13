/*   
*   Copyright (c) Rich Hickey. All rights reserved.
*   The use and distribution terms for this software are covered by the
*   Common Public License 1.0 (http://opensource.org/licenses/cpl.php)
*   which can be found in the file CPL.TXT at the root of this distribution.
*   By using this software in any fashion, you are agreeing to be bound by
* 	the terms of this license.
*   You must not remove this notice, or any other, from this software.
*/


package com.las3r.io{

	public class CharBuffer{

		private var _contents:Array = [];
		private var _position:int = 0;



		public function get position():int{
			return _position;
		}

		public function get remaining():int{
			return (_contents.length - 1) - _position;
		}


		/* Writes the content of the the <code>char array</code> src
		* into the buffer. Before the transfer, it checks if there is fewer than
		* length space remaining in this buffer.
		*
		* @param src The array to copy into the buffer.
		* @param offset The offset within the array of the first byte to be read;
		* must be non-negative and no larger than src.length.
		* @param length The number of bytes to be read from the given array;
		* must be non-negative and no larger than src.length - offset.
		* 
		* @exception BufferOverflowException If there is insufficient space in this
		* buffer for the remaining <code>char</code>s in the source array.
		* @exception IndexOutOfBoundsException If the preconditions on the offset
		* and length parameters do not hold
		* @exception ReadOnlyBufferException If this buffer is read-only.
		*/
		public function put(src:Array, offset:int, length:int):CharBuffer {
			var i:int = 0;
			var j:int = _position;
			while(i < src.length && j < _contents.length){
				_contents[j] = src[i];
				i++;
				j++;
			}
			return this;
		}


	}
}

