/**
 * Copyright (c) 2007-2008, the original author(s)
 * 
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 *     * Redistributions of source code must retain the above copyright notice,
 *       this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the Prana Framework nor the names of its contributors
 *       may be used to endorse or promote products derived from this software
 *       without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
package org.pranaframework.reflection {
	
	/**
	 * TypeSafe enum of an accessor's access properties.
	 * 
	 * @author Christophe Herreman
	 * @see Accessor
	 */
	public final class AccessorAccess {
		
		/**
		 * Creates a new <code>AccessorAccess</code> instance.
		 * 
		 * @param name the name of the accessor access
		 */
		public function AccessorAccess(name:String) {
			_name = name;
		}
		
		/**
		 * 
		 */
		public static function fromString(access:String):AccessorAccess {
			var result:AccessorAccess;
			switch (access) {
				case READ_ONLY_VALUE:
					result = READ_ONLY;
					break;
				case WRITE_ONLY_VALUE:
					result = WRITE_ONLY;
					break;
				case READ_WRITE_VALUE:
					result = READ_WRITE;
					break;
			}
			return result;
		}
		
		/**
		 * 
		 */
		public function get name():String {
			return _name;
		}
		
		public static const READ_ONLY:AccessorAccess = new AccessorAccess(READ_ONLY_VALUE);
		public static const WRITE_ONLY:AccessorAccess = new AccessorAccess(WRITE_ONLY_VALUE);
		public static const READ_WRITE:AccessorAccess = new AccessorAccess(READ_WRITE_VALUE);
		
		private static const READ_ONLY_VALUE:String = "readonly";
		private static const WRITE_ONLY_VALUE:String = "writeonly";
		private static const READ_WRITE_VALUE:String = "readwrite";
		
		private var _name:String;
	}
}