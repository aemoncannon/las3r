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
	
	import flash.utils.Proxy;
	
	/**
	 * Provides information about a single method of a class or interface.
	 * 
	 * @author Christophe Herreman
	 */
	public class Method {
		
		/**
		 * Creates a new <code>Method</code> instance.
		 */
		public function Method(declaringType:Type, name:String, isStatic:Boolean, parameters:Array, returnType:*) {
			_declaringType = declaringType;
			_name = name;
			_isStatic = isStatic;
			_parameters = parameters;
			_returnType = returnType;
		}
		
		/**
		 * Invokes (calls) the method represented by this <code>Method</code>
		 * instance of the given <code>target</code> object with the passed in
		 * arguments.
		 * 
		 * @param target the object on which to invoke the method
		 * @param args the arguments that will be passed along the method call
		 * @return the result of the method invocation, if any
		 */
		public function invoke(target:*, args:Array):* {
			var result:*;
			if (target is Proxy) {
				//var a:Array = [name].concat(args);
				//result = Proxy(target).flash_proxy::callProperty.apply(target, a);
			}
			else {
				result = target[name].apply(target, args);
			}
			return result;
		}
		
		public function get declaringType():Type { return _declaringType; };
		public function get name():String { return _name; };
		public function get isStatic():Boolean { return _isStatic; };
		public function get parameters():Array { return _parameters; };
		public function get returnType():Type { return _returnType; };
		
		public function get fullName():String {
			var result:String = "public ";
			if (isStatic) result += "static ";
			result += name + "(";
			for (var i:int=0; i<parameters.length; i++) {
				var p:Parameter = parameters[i] as Parameter;
				result += p.type.name;
				result += (i < (parameters.length-1)) ? ", " : "";
			}
			result += "):" + returnType.name;
			return result;
		}
		
		/**
		 * 
		 */
		public function toString():String {
			return "[Method(name:'" + name + "', isStatic:" + isStatic + ")]";
		}
		
		private var _declaringType:Type;
		private var _name:String;
		private var _isStatic:Boolean;
		private var _parameters:Array;
		private var _returnType:Type;
	}
}