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