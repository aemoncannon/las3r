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

	public interface Readable{


		/* Attempts to read characters into the specified character buffer.
		* The buffer is used as a repository of characters as-is: the only
		* changes made are the results of a put operation. No flipping or
		* rewinding of the buffer is performed.
		*
		* @param cb the buffer to read characters into
		* @return @return The number of <tt>char</tt> values added to the buffer,
		*                 or -1 if this source of characters is at its end
		* @throws IOException if an I/O error occurs
		* @throws NullPointerException if cb is null
		* @throws ReadOnlyBufferException if cb is a read only buffer
		*/
		function read(cb:CharBuffer):int;


	}




}