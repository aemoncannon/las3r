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
	* Abstract class for reading filtered character streams.
	* The abstract class <code>FilterReader</code> itself
	* provides default methods that pass all requests to
	* the contained stream. Subclasses of <code>FilterReader</code>
	* should override some of these methods and may also provide
	* additional methods and fields.
	*/

	public class FilterReader extends Reader {
		
		/**
		* The underlying character-input stream.
		*/
		protected var _in:Reader;
		
		/**
		* Creates a new filtered reader.
		*
		* @param in  a Reader object providing the underlying stream.
		* @throws NullPointerException if <code>in</code> is <code>null</code>
		*/
		public function FilterReader(reader:Reader) {
			super();
			this._in = reader;
		}
		
		/**
		* Reads a single character.
		*
		* @exception  IOException  If an I/O error occurs
		*/
		override public function readOne():int {
			return _in.readOne();
		}
		
		/**
		* Reads characters into a portion of an array.
		*
		* @exception  IOException  If an I/O error occurs
		*/
		override public function readIntoArrayAt(cbuf:Array, off:int, len:int):int {
			return _in.readIntoArrayAt(cbuf, off, len);
		}
		
		/**
		* Skips characters.
		*
		* @exception  IOException  If an I/O error occurs
		*/
		override public function skip(n:int):int{
			return _in.skip(n);
		}
		
		/**
		* Tells whether this stream is ready to be read.
		*
		* @exception  IOException  If an I/O error occurs
		*/
		override public function ready():Boolean{
			return _in.ready();
		}
		
		/**
		* Tells whether this stream supports the mark() operation.
		*/
		override public function markSupported():Boolean {
			return _in.markSupported();
		}
		
		/**
		* Marks the present position in the stream.
		*
		* @exception  IOException  If an I/O error occurs
		*/
		override public function mark(readAheadLimit:int):void {
			_in.mark(readAheadLimit);
		}
		
		/**
		* Resets the stream.
		*
		* @exception  IOException  If an I/O error occurs
		*/
		override public function reset():void {
			_in.reset();
		}
		
		override public function close():void {
			_in.close();
		}
		
	}

}