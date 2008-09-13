/**
* Copyright (c) Rich Hickey. All rights reserved.
* The use and distribution terms for this software are covered by the
* Common Public License 1.0 (http://opensource.org/licenses/cpl.php)
* which can be found in the file CPL.TXT at the root of this distribution.
* By using this software in any fashion, you are agreeing to be bound by
* the terms of this license.
* You must not remove this notice, or any other, from this software.
*/


package com.las3r.util
{
	public class ArrayUtil
	{
		
		/**
        * @param      src      the source array.
        * @param      srcPos   starting position in the source array.
        * @param      dest     the destination array.
        * @param      destPos  starting position in the destination data.
        * @param      length   the number of array elements to be copied.
        * @exception  IndexOutOfBoundsException  if copying would cause
        *               access of data outside array bounds.
        * @exception  ArrayStoreException  if an element in the <code>src</code>
        *               array could not be stored into the <code>dest</code> array
        *               because of a type mismatch.
        * @exception  NullPointerException if either <code>src</code> or
        *               <code>dest</code> is <code>null</code>.
        */
		public static function arraycopy(src:Array,  srcPos:int, dest:Array, destPos:int, length:int):void{
			var iterations:int = Math.min(Math.min(length, src.length - srcPos), dest.length - destPos);
			for(var i:int = 0; i < iterations; i++){
				dest[destPos + i] = src[srcPos + i];
			}
		}
		
	}
}