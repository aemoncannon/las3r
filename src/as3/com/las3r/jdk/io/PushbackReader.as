/*
* This code was ported for las3r from it's original Java. The following notice
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

package com.las3r.jdk.io{
    
    import com.las3r.jdk.util.ArrayUtil;
    /**
    * A character-stream reader that allows characters to be pushed back into the
    * stream.
    */
    
    public class PushbackReader extends FilterReader {
		
        /** Pushback buffer */
        private var buf:Array;
		
        /** Current position in buffer */
        private var pos:int;
		
        /**
        * Creates a new pushback reader with a pushback buffer of the given size.
        *
        * @param   in   The reader from which characters will be read
        * @param   size The size of the pushback buffer
        * @exception IllegalArgumentException if size is <= 0
        */
        public function PushbackReader(reader:Reader, size:int = 1) {
            super(reader);
            if (size <= 0) {
                throw new Error("IllegalArgumentException: size <= 0");
            }
            this.buf = new Array(size);
            this.pos = size;
        }
		
        /** Checks to make sure that the stream has not been closed. */
        private function ensureOpen():void {
            if (buf == null){
				throw new Error("IOException: Stream closed");
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
            if (pos < buf.length){
				return buf[pos++];
			}
            else{
				return super.readOne();
			}
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
        override public function readIntoArrayAt(cbuf:Array, off:int, len:int):int{
            ensureOpen();
            try {
                if (len <= 0) {
                    if (len < 0) {
                        throw new Error("IndexOutOfBoundsException");
                    } else if ((off < 0) || (off > cbuf.length)) {
                        throw new Error("IndexOutOfBoundsException");
                    }
                    return 0;
                }
                var avail:int = buf.length - pos;
                if (avail > 0) {
                    if (len < avail){
						avail = len;
					}

                    ArrayUtil.arraycopy(buf, pos, cbuf, off, avail);

                    pos += avail;
                    off += avail;
                    len -= avail;
                }
                if (len > 0) {
                    len = super.readIntoArrayAt(cbuf, off, len);
                    if (len == -1) {
                        return (avail == 0) ? -1 : avail;
                    }
                    return avail + len;
                }
                return avail;
            } catch (e:Error) {
                throw new Error("IndexOutOfBoundsException");
            }
			return -1;
        }
		
        /**
        * Pushes back a single character by copying it to the front of the
        * pushback buffer. After this method returns, the next character to be read
        * will have the value <code>(char)c</code>.
        *
        * @param  c  The int value representing a character to be pushed back
        *
        * @exception  IOException  If the pushback buffer is full,
        *                          or if some other I/O error occurs
        */
        public function unread(c:int):void {
            ensureOpen();
            if (pos == 0){
				throw new Error("IOException: Pushback buffer overflow");
			}
            buf[--pos] = c;
        }
		
        /**
        * Pushes back a portion of an array of characters by copying it to the
        * front of the pushback buffer.  After this method returns, the next
        * character to be read will have the value <code>cbuf[off]</code>, the
        * character after that will have the value <code>cbuf[off+1]</code>, and
        * so forth.
        *
        * @param  cbuf  Character array
        * @param  off   Offset of first character to push back
        * @param  len   Number of characters to push back
        *
        * @exception  IOException  If there is insufficient room in the pushback
        *                          buffer, or if some other I/O error occurs
        */
        public function unreadArrayAt(cbuf:Array, off:int, len:int):void {
            ensureOpen();
            if (len > pos){
				throw new Error("IOException: Pushback buffer overflow");
			}
            pos -= len;
            ArrayUtil.arraycopy(cbuf, off, buf, pos, len);
        }
		
        /**
        * Pushes back an array of characters by copying it to the front of the
        * pushback buffer.  After this method returns, the next character to be
        * read will have the value <code>cbuf[0]</code>, the character after that
        * will have the value <code>cbuf[1]</code>, and so forth.
        *
        * @param  cbuf  Character array to push back
        *
        * @exception  IOException  If there is insufficient room in the pushback
        *                          buffer, or if some other I/O error occurs
        */
        public function unreadArray(cbuf:Array):void {
            unreadArrayAt(cbuf, 0, cbuf.length);
        }
		
        /**
        * Tells whether this stream is ready to be read.
        *
        * @exception  IOException  If an I/O error occurs
        */
        override public function ready():Boolean {
            ensureOpen();
            return (pos < buf.length) || super.ready();
        }
		
        /**
        * Marks the present position in the stream. The <code>mark</code>
        * for class <code>PushbackReader</code> always throws an exception.
        *
        * @exception  IOException  Always, since mark is not supported
        */
        override public function mark(readAheadLimit:int):void {
            throw new Error("IOException: mark/reset not supported");
        }
		
        /**
        * Resets the stream. The <code>reset</code> method of
        * <code>PushbackReader</code> always throws an exception.
        *
        * @exception  IOException  Always, since reset is not supported
        */
        override public function reset():void {
            throw new Error("IOException: mark/reset not supported");
        }
		
        /**
        * Tells whether this stream supports the mark() operation, which it does
        * not.
        */
        override public function markSupported():Boolean {
            return false;
        }
		
        /**
        * Closes the stream and releases any system resources associated with
        * it. Once the stream has been closed, further read(),
        * unread(), ready(), or skip() invocations will throw an IOException.
        * Closing a previously closed stream has no effect.
        *
        * @exception  IOException  If an I/O error occurs
        */
        override public function close():void {
            super.close();
            buf = null;
        }
		
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
        override public function skip(n:int):int {
            if (n < 0){
				throw new Error("IllegalArgumentException: skip value is negative");
			}
            ensureOpen();
            var avail:int = buf.length - pos;
            if (avail > 0) {
                if (n <= avail) {
                    pos += n;
                    return n;
                } else {
                    pos = buf.length;
                    n -= avail;
                }
            }
            return avail + super.skip(n);
        }
    }

}

