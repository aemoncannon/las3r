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
 package org.pranaframework.utils {
	
	import flash.net.ObjectEncoding;
	import flash.net.registerClassAlias;
	import flash.utils.ByteArray;
	import flash.utils.describeType;
	import flash.utils.getQualifiedClassName;
	
	import mx.utils.ObjectUtil;
	
	/**
	 * ObjectsUtils contains utility methods for working with objects.
	 * 
	 * @author Christophe Herreman
	 */
	public class ObjectUtils {
		
		public static function clone(object:Object):* {
			var byteArray:ByteArray = new ByteArray();
			byteArray.writeObject(object);
			byteArray.position = 0;
			return byteArray.readObject();
		}
		
		/**
		 * Converts a plain vanilla object to be an instance of the class
		 * passed as the second variable.  This is not a recursive funtion
		 * and will only work for the first level of nesting.  When you have
		 * deeply nested objects, you first need to convert the nested
		 * objects to class instances, and then convert the top level object.
		 * 
		 * TODO: This method can be improved by making it recursive.  This would be 
		 * done by looking at the typeInfo returned from describeType and determining
		 * which properties represent custom classes.  Those classes would then
		 * be registerClassAlias'd using getDefinititonByName to get a reference,
		 * and then objectToInstance would be called on those properties to complete
		 * the recursive algorithm.
		 * 
		 * @author Darron Schall (darron@darronschall.com)
		 * http://www.darronschall.com/weblog/archives/000247.cfm
		 * 
		 * @param object The plain object that should be converted
		 * @param clazz The type to convert the object to
		 */
		public static function toInstance( object:Object, clazz:Class ):* {
			var bytes:ByteArray = new ByteArray();
			bytes.objectEncoding = ObjectEncoding.AMF0;
			
			// Find the objects and byetArray.writeObject them, adding in the
			// class configuration variable name -- essentially, we're constructing
			// and AMF packet here that contains the class information so that
			// we can simplly byteArray.readObject the sucker for the translation
			
			// Write out the bytes of the original object
			var objBytes:ByteArray = new ByteArray();
			objBytes.objectEncoding = ObjectEncoding.AMF0;
			objBytes.writeObject( object );
					
			// Register all of the classes so they can be decoded via AMF
			var typeInfo:XML = describeType( clazz );
			var fullyQualifiedName:String = typeInfo.@name.toString().replace( /::/, "." );
			registerClassAlias( fullyQualifiedName, clazz );
			
			// Write the new object information starting with the class information
			var len:int = fullyQualifiedName.length;
			bytes.writeByte( 0x10 );  // 0x10 is AMF0 for "typed object (class instance)"
			bytes.writeUTF( fullyQualifiedName );
			// After the class name is set up, write the rest of the object
			bytes.writeBytes( objBytes, 1 );
			
			// Read in the object with the class property added and return that
			bytes.position = 0;
			
			// This generates some ReferenceErrors of the object being passed in
			// has properties that aren't in the class instance, and generates TypeErrors
			// when property values cannot be converted to correct values (such as false
			// being the value, when it needs to be a Date instead).  However, these
			// errors are not thrown at runtime (and only appear in trace ouput when
			// debugging), so a try/catch block isn't necessary.  I'm not sure if this
			// classifies as a bug or not... but I wanted to explain why if you debug
			// you might seem some TypeError or ReferenceError items appear.
			var result:* = bytes.readObject();
			return result;
		}
		
		/**
		 * Checks if the given object is an explicit instance of the given class.
		 * 
		 * <p>That means that true will only be returned if the object
		 * was instantiated directly from the given class.</p>
		 * 
		 * @param object the object to check
		 * @param clazz the class from which the object should be an explicit instance
		 * @return true if the object is an explicit instance of the class, false if not
		 */
		public static function isExplicitInstanceOf(object:Object, clazz:Class):Boolean {
			var c:Class = ClassUtils.forInstance(object);
			return (c == clazz);
		}
		
		/**
		 * Wraps ObjectUtil.getClassInfo() and adds support for the following
		 * primitive types: String, Number, int, uint, Boolean, Date and Array.
		 */
		public static function getClassInfo(object:Object):Object {
			var result:Object = {};
			var isPrimitive:Boolean = ObjectUtil.isSimple(object);
			
			if (isPrimitive) {
				var type:String = typeof(object);
				switch (type) {
					case "number":
						if (object is uint) {
							result.name = "uint";
						}
						else if (object is int) {
							result.name = "int";
						}
						else if (object is Number) {
							result.name = "Number";
						}
						break;
					case "string":
						result.name = "String";
						break;
					case "boolean":
						result.name = "Boolean";
						break;
					case "object":
						if (object is Date) result.name = "Date";
						if (object is Array) result.name = "Array";
        				break;
				}
			}
			else {
				result = ObjectUtil.getClassInfo(object);
			}
			return result;
		}
		
		public static function getFullQualifiedClassName(object:Object):String {
			return getQualifiedClassName(object);
		}
		
		/**
		 * Returns the number of properties in this object.
		 */
		public static function getNumProperties(object:Object):int {
			var result:int = 0;
			for (var p:String in object) {
				result++;
			}
			return result;
		}
		
		/**
		 * Returns an array with the keys of this object.
		 */
		public static function getKeys(object:Object):Array {
			var result:Array = [];
			for (var k:* in object) {
				result.push(k);
			}
			return result;
		}
		
	}
}