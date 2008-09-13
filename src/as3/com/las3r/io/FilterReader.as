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