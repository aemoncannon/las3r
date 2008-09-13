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
	 * The base class for members of a <code>class</object>.
	 * 
	 * Note: this class is immutable
	 * 
	 * @author Christophe Herreman
	 */
	public class AbstractMember implements IMember {
		
		/**
		 * Creates a new AbstractMember object.
		 * 
		 * @param name the name of the member
		 * @param type the type of the member
		 * @param declaringType the type that declares the member
		 */
		public function AbstractMember(name:String, type:Type, declaringType:Type, isStatic:Boolean) {
			_name = name;
			_type = type;
			_declaringType = declaringType;
			_isStatic = isStatic;
		}
		
		public function get declaringType():Type {
			return _declaringType;
		}
		
		public function get name():String {
			return _name;
		}
		
		public function get type():Type {
			return _type;
		}
		
		public function get isStatic():Boolean {
			return _isStatic;
		}
		
		private var _name:String;
		private var _type:Type;
		private var _declaringType:Type;
		private var _isStatic:Boolean;
	}
}