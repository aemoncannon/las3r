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

	/**
    * A character stream whose source is a string.
    *
    */
    public class StringReader extends Reader {
		
        private var str:String;
        private var length:int;
        private var next:int = 0;
        private var _mark:int = 0;
		
        /**
        * Creates a new string reader.
        *
        * @param s  String providing the character stream.
        */
        public function StringReader(s:String) {
            this.str = s;
            this.length = s.length;
        }
		
        /** Check to make sure that the stream has not been closed */
        private function ensureOpen():void {
            if (str == null){
				throw new Error("Stream closed");
			}
        }
		
        /**
        * Reads a single character.
        *
        * @return     The character read, or -1 if the end of the stream has been
        *             reached
        *
        * @exception  IOException  If an I/O error occurs
        */
        override public function readOne():int{
            ensureOpen();
            if (next >= length){
				return -1;
			}
            return int(str.charCodeAt(next++));
        }
		
        /**
        * Reads characters into a portion of an array.
        *
        * @param      cbuf  Destination buffer
        * @param      off   Offset at which to start writing characters
        * @param      len   Maximum number of characters to read
        *
        * @return     The number of characters read, or -1 if the end of the
        *             stream has been reached
        *
        * @exception  IOException  If an I/O error occurs
        */
        override public function readIntoArrayAt(cbuf:Array, off:int, len:int):int {
            ensureOpen();
            if ((off < 0) || (off > cbuf.length) || (len < 0) ||
                ((off + len) > cbuf.length) || ((off + len) < 0)) {
                throw new Error("IndexOutOfBounds");
            } else if (len == 0) {
                return 0;
            }
            if (next >= length){
				return -1;
			}
            var n:int = Math.min(length - next, len);

			for(var i:int = next; i <= (next + n); i++){
				var j:int = i + off;
				if(j < cbuf.length){
					cbuf[j] = int(str.charCodeAt(i));
				}
				else{
					break;
				}
			}
            next += n;
            return n;
        }
		
        /**
        * Skips the specified number of characters in the stream. Returns
        * the number of characters that were skipped.
        *
        * <p>The <code>ns</code> parameter may be negative, even though the
        * <code>skip</code> method of the {@link Reader} superclass throws
        * an exception in this case. Negative values of <code>ns</code> cause the
        * stream to skip backwards. Negative return values indicate a skip
        * backwards. It is not possible to skip backwards past the beginning of
        * the string.
        *
        * <p>If the entire string has been read or skipped, then this method has
        * no effect and always returns 0.
        *
        * @exception  IOException  If an I/O error occurs
        */
        override public function skip(ns:int):int {
            ensureOpen();
            if (next >= length){
				return 0;
			}
            // Bound skip by beginning and end of the source
            var n:int = Math.min(length - next, ns);
            n = Math.max(-next, n);
            next += n;
            return n;
        }
		
        /**
        * Tells whether this stream is ready to be read.
        *
        * @return True if the next read() is guaranteed not to block for input
        *
        * @exception  IOException  If the stream is closed
        */
        override public function ready():Boolean {
			ensureOpen();
			return true;
        }
		
        /**
        * Tells whether this stream supports the mark() operation, which it does.
        */
        override public function markSupported():Boolean {
            return true;
        }
		
        /**
        * Marks the present position in the stream.  Subsequent calls to reset()
        * will reposition the stream to this point.
        *
        * @param  readAheadLimit  Limit on the number of characters that may be
        *                         read while still preserving the mark.  Because
        *                         the stream's input comes from a string, there
        *                         is no actual limit, so this argument must not
        *                         be negative, but is otherwise ignored.
        *
        * @exception  IllegalArgumentException  If readAheadLimit is < 0
        * @exception  IOException  If an I/O error occurs
        */
        override public function mark(readAheadLimit:int):void {
            if (readAheadLimit < 0){
                throw new Error("Read-ahead limit < 0");
            }
            ensureOpen();
            _mark = next;
        }
		
        /**
        * Resets the stream to the most recent mark, or to the beginning of the
        * string if it has never been marked.
        *
        * @exception  IOException  If an I/O error occurs
        */
        override public function reset():void {
            ensureOpen();
            next = _mark;
        }
		
        /**
        * Closes the stream and releases any system resources associated with
        * it. Once the stream has been closed, further read(),
        * ready(), mark(), or reset() invocations will throw an IOException.
        * Closing a previously closed stream has no effect.
        */
        override public function close():void {
            str = null;
        }



	}

}