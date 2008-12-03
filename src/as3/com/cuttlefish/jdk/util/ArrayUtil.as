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

package com.cuttlefish.jdk.util
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