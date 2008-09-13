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

	/* Abstract class for reading character streams.  The only methods that a
    * subclass must implement are read(char[], int, int) and close().
    */
	public class Reader implements Readable{
		
		/**
        * The object used to synchronize operations on this stream.  For
        * efficiency, a character-stream object may use an object other than
        * itself to protect critical sections.  A subclass should therefore use
        * the object in this field rather than <tt>this</tt> or a synchronized
        * method.
        */
		
		/**
        * Creates a new character-stream reader whose critical sections will
        * synchronize on the reader itself.
        */
		public function Reader() {}

		/**
        * Attempts to read characters into the specified character buffer.
        * The buffer is used as a repository of characters as-is: the only
        * changes made are the results of a put operation. No flipping or
        * rewinding of the buffer is performed.
        *
        * @param target the buffer to read characters into
        * @return The number of characters added to the buffer, or
        *         -1 if this source of characters is at its end
        */
		public function read(target:CharBuffer):int{
			var len:int = target.remaining;
			var cbuf:Array = new Array(len);
			var n:int = readIntoArrayAt(cbuf, 0, len);
			if (n > 0){
				target.put(cbuf, 0, n);
			}
			return n;
		}
		
		/**
        * Reads a single character.  This method will block until a character is
        * available, an I/O error occurs, or the end of the stream is reached.
        *
        * <p> Subclasses that intend to support efficient single-character input
        * should override this method.
        *
        * @return     The character read, as an integer in the range 0 to 65535
        *             (<tt>0x00-0xffff</tt>), or -1 if the end of the stream has
        *             been reached
        *
        * @exception  IOException  If an I/O error occurs
        */
		public function readOne():int {
			var cb:Array = new Array(1);
			if (readIntoArrayAt(cb, 0, 1) == -1){
				return -1;
			}
			else{
				return cb[0];
			}
		}
		
		/**
        * Reads characters into an array.  This method will block until some input
        * is available, an I/O error occurs, or the end of the stream is reached.
        *
        * @param       cbuf  Destination buffer
        *
        * @return      The number of characters read, or -1
        *              if the end of the stream
        *              has been reached
        *
        * @exception   IOException  If an I/O error occurs
        */
		public function readIntoArray(cbuf:Array):int {
			return readIntoArrayAt(cbuf, 0, cbuf.length);
		}
		
		/**
        * Reads characters into a portion of an array.  This method will block
        * until some input is available, an I/O error occurs, or the end of the
        * stream is reached.
        *
        * @param      cbuf  Destination buffer
        * @param      off   Offset at which to start storing characters
        * @param      len   Maximum number of characters to read
        *
        * @return     The number of characters read, or -1 if the end of the
        *             stream has been reached
        *
        * @exception  IOException  If an I/O error occurs
        */
		public function readIntoArrayAt(cbuf:Array, off:int, len:int):int{ throw "SubclassResponsibility"; }
		
		/** Maximum skip-buffer size */
		private static const maxSkipBufferSize:int = 8192;
		
		/** Skip buffer, null until allocated */
		private var skipBuffer:Array = null;
		
		/**
        * Skips characters.  This method will block until some characters are
        * available, an I/O error occurs, or the end of the stream is reached.
        *
        * @param  n  The number of characters to skip
        *
        * @return    The number of characters actually skipped
        *
        * @exception  IllegalArgumentException  If <code>n</code> is negative.
        * @exception  IOException  If an I/O error occurs
        */
		public function skip(n:int):int{
			if (n < 0){
				throw new Error("skip value is negative");
			}
			var nn:int = int(Math.min(n, maxSkipBufferSize));
			if ((skipBuffer == null) || (skipBuffer.length < nn)){
				skipBuffer = new Array(nn);
			}
			var r:int = n;
			while (r > 0) {
				var nc:int = readIntoArrayAt(skipBuffer, 0, int(Math.min(r, nn)));
				if (nc == -1){
					break;
				}
				r -= nc;
			}
			return n - r;
		}
		
		/**
        * Tells whether this stream is ready to be read.
        *
        * @return True if the next read() is guaranteed not to block for input,
        * false otherwise.  Note that returning false does not guarantee that the
        * next read will block.
        *
        * @exception  IOException  If an I/O error occurs
        */
		public function ready():Boolean {
			return false;
		}
		
		/**
        * Tells whether this stream supports the mark() operation. The default
        * implementation always returns false. Subclasses should override this
        * method.
        *
        * @return true if and only if this stream supports the mark operation.
        */
		public function markSupported():Boolean {
			return false;
		}
		
		/**
        * Marks the present position in the stream.  Subsequent calls to reset()
        * will attempt to reposition the stream to this point.  Not all
        * character-input streams support the mark() operation.
        *
        * @param  readAheadLimit  Limit on the number of characters that may be
        *                         read while still preserving the mark.  After
        *                         reading this many characters, attempting to
        *                         reset the stream may fail.
        *
        * @exception  IOException  If the stream does not support mark(),
        *                          or if some other I/O error occurs
        */
		public function mark(readAheadLimit:int):void {
			throw new Error("mark() not supported");
		}
		
		/**
        * Resets the stream.  If the stream has been marked, then attempt to
        * reposition it at the mark.  If the stream has not been marked, then
        * attempt to reset it in some way appropriate to the particular stream,
        * for example by repositioning it to its starting point.  Not all
        * character-input streams support the reset() operation, and some support
        * reset() without supporting mark().
        *
        * @exception  IOException  If the stream has not been marked,
        *                          or if the mark has been invalidated,
        *                          or if the stream does not support reset(),
        *                          or if some other I/O error occurs
        */
		public function reset():void{
			throw new Error("reset() not supported");
		}
		
		/**
        * Closes the stream and releases any system resources associated with
        * it.  Once the stream has been closed, further read(), ready(),
        * mark(), reset(), or skip() invocations will throw an IOException.
        * Closing a previously closed stream has no effect.
        *
        * @exception  IOException  If an I/O error occurs
        */
        public function close():void{ 
			throw new Error(); 
		}
		
	}


}