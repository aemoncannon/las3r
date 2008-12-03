/*
* This code was ported for cuttlefish from it's original Java. The following notice
* was not altered. See readme.txt in the root of this distribution for more 
* information.
* -----------------------------------------------------------------
*
* Copyright 1996-2006 Sun Microsystems, Inc.  All Rights Reserved.
* DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
*
* This code is free software; you can redistribute it and/or modify it
* under the terms of the GNU General Public License version 2 only, as
* published by the Free Software Foundation.  Sun designates this
* particular file as subject to the "Classpath" exception as provided
* by Sun in the LICENSE file that accompanied this code.
*
* This code is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
* FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
* version 2 for more details (a copy is included in the readme.txt file that
* accompanied this code).
*
* You should have received a copy of the GNU General Public License version
* 2 along with this work; if not, write to the Free Software Foundation,
* Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
*
* Please contact Sun Microsystems, Inc., 4150 Network Circle, Santa Clara,
* CA 95054 USA or visit www.sun.com if you need additional information or
* have any questions.
*/


package com.cuttlefish.jdk.io{

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

