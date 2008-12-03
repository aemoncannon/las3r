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

			for(var i:int = 0; i < n; i++){
				var j:int = off + i;
				if(j < cbuf.length){
					cbuf[j] = int(str.charCodeAt(next + i));
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