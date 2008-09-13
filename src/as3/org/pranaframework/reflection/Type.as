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
	
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	
	import org.pranaframework.utils.ClassUtils;
	
	/**
	 * Provides information about the characteristics of a class or an interface.
	 * These are the methods, accessors (getter/setter), variables and constants,
	 * but also if the class is <code>dynamic</code> and <code>final</code>.
	 * 
	 * <p>Note that information about an object cannot be retrieved by calling the
	 * <code>Type</code> constructor. Instead use one of the following static
	 * methods:</p>
	 * 
	 * <p>In case of an instance:
	 * <code>var type:Type = Type.forInstance(myInstance);</code>
	 * </p>
	 * 
	 * <p>In case of a <code>Class</code> variable:
	 * <code>var type:Type = Type.forClass(MyClass);</code>
	 * </p>
	 * 
	 * <p>In case of a classname:
	 * <code>var type:Type = Type.forName("MyClass");</code>
	 * </p>
	 */
	public class Type {
		
		/**
		 * Creates a new <code>Type</code> instance.
		 */
		public function Type() {
			_methods = new Array();
			_accessors = new Array();
			_staticConstants = new Array();
			_constants = new Array();
			_staticVariables = new Array();
			_variables = new Array();
			_fields = new Array();
		}
		
		/**
		 * Returns a <code>Type</code> object that describes the given instance.
		 * 
		 * @param instance the instance from which to get a type description
		 */
		public static function forInstance(instance:*):Type {
			var result:Type;
			var clazz:Class = ClassUtils.forInstance(instance);
			if (clazz != null) {
				result = Type.forClass(clazz);
			}
			return result;
		}
		
		/**
		 * Returns a <code>Type</code> object that describes the given classname.
		 * 
		 * @param name the classname from which to get a type description
		 */
		public static function forName(name:String):Type {
			var result:Type;
			/*if(name.indexOf("$")!=-1){
				return Type.PRIVATE;
			}*/
			switch (name) {
				case "void":
					result = Type.VOID;
					break;
				case "*":
					result = Type.UNTYPED;
					break;
				default:
					try {
						result = Type.forClass(Class(getDefinitionByName(name)));
					}
					catch (e:ReferenceError) {
						trace("Type.forName error: " + e.message + " The class '" + name + "' is probably an internal class or it may not have been compiled.");
					}
					
			}
			return result;
		}
		
		/**
		 * Returns a <code>Type</code> object that describes the given class.
		 * 
		 * @param clazz the class from which to get a type description
		 */
		public static function forClass(clazz:Class):Type {
			var result:Type;
			var fullyQualifiedClassName:String = ClassUtils.getFullyQualifiedName(clazz);
			
			if (_cache[fullyQualifiedClassName]) {
				result = _cache[fullyQualifiedClassName];
			}
			else {
				var description:XML = describeType(clazz);
				result = new Type();
				// add the Type to the cache before assigning any values to prevent looping
				_cache[fullyQualifiedClassName] = result;
				result.fullName = fullyQualifiedClassName;
				result.name = ClassUtils.getNameFromFullyQualifiedName(fullyQualifiedClassName);
				result.clazz = clazz;
				result.isDynamic = description.@isDynamic;
				result.isFinal = description.@isFinal;
				result.isStatic = description.@isStatic;
				result.accessors = TypeXmlParser.parseAccessors(result, description);
				result.methods = TypeXmlParser.parseMethods(result, description);
				result.staticConstants = TypeXmlParser.parseMembers(Constant, description.constant, result, true);
				result.constants = TypeXmlParser.parseMembers(Constant, description.factory.constant, result, false);
				result.staticVariables = TypeXmlParser.parseMembers(Variable, description.variable, result, true);
				result.variables = TypeXmlParser.parseMembers(Variable, description.factory.variable, result, false);
			}
			
			return result;
		}
		
		/**
		 * Returns the <code>Method</code> object for the method in this type
		 * with the given name.
		 * 
		 * @param name the name of the method
		 */
		public function getMethod(name:String):Method {
			var result:Method;
			for each (var method:Method in methods) {
				if (method.name == name) {
					result = method;
					break;
				}
			}
			return result;
		}
		
		/**
		 * Returns the <code>Field</code> object for the field in this type
		 * with the given name.
		 * 
		 * @param name the name of the field
		 */
		public function getField(name:String):Field {
			var result:Field;
			for each (var field:Field in fields) {
				if (field.name == name) {
					result = field;
					break;
				}
			}
			return result;
		}
		
		public function get name():String { return _name; }
		public function set name(value:String):void { _name = value; }
		
		public function get fullName():String { return _fullName; }
		public function set fullName(value:String):void { _fullName = value; }
		
		public function get clazz():Class { return _class; }
		public function set clazz(value:Class):void { _class = value; }
		
		public function get isDynamic():Boolean { return _isDynamic; }
		public function set isDynamic(value:Boolean):void { _isDynamic = value; }
		
		public function get isFinal():Boolean { return _isFinal; }
		public function set isFinal(value:Boolean):void { _isFinal = value; }
		
		public function get isStatic():Boolean { return _isStatic; }
		public function set isStatic(value:Boolean):void { _isStatic = value; }
		
		public function get accessors():Array { return _accessors; }
		public function set accessors(value:Array):void { _accessors = value; }
		
		public function get methods():Array { return _methods; }
		public function set methods(value:Array):void { _methods = value; }
		
		public function get staticConstants():Array { return _staticConstants; }
		public function set staticConstants(value:Array):void { _staticConstants = value; }
		
		public function get constants():Array { return _constants; }
		public function set constants(value:Array):void { _constants = value; }
		
		public function get staticVariables():Array { return _staticVariables; }
		public function set staticVariables(value:Array):void { _staticVariables = value; }
		
		public function get variables():Array { return _variables; }
		public function set variables(value:Array):void { _variables = value; }
		
		public function get fields():Array {
			return accessors.concat(staticConstants).concat(constants).concat(staticVariables).concat(variables);
		}
		
		public static const UNTYPED:Type = new Type();
		public static const VOID:Type = new Type();
		public static const PRIVATE:Type = new Type();
		
		private static var _cache:Object = {};
		
		private var _name:String;
		private var _fullName:String;
		private var _isDynamic:Boolean;
		private var _isFinal:Boolean;
		private var _isStatic:Boolean;
		private var _methods:Array;
		private var _accessors:Array;
		private var _staticConstants:Array;
		private var _constants:Array;
		private var _staticVariables:Array;
		private var _variables:Array;
		private var _fields:Array;
		private var _class:Class;
		
	}
}

import org.pranaframework.reflection.Method;
import org.pranaframework.reflection.Type;
import org.pranaframework.reflection.Parameter;
import org.pranaframework.reflection.Accessor;
import org.pranaframework.reflection.AccessorAccess;
import org.pranaframework.reflection.IMember;
import org.pranaframework.reflection.MetaData;

/**
 * Internal xml parser
 */
class TypeXmlParser {
	public static function parseMethods(type:Type, xml:XML):Array {
		var classMethods:Array = parseMethodsByModifier(type, xml.method, true);
		var instanceMethods:Array = parseMethodsByModifier(type, xml.factory.method, false);
		return classMethods.concat(instanceMethods);
	}
	public static function parseAccessors(type:Type, xml:XML):Array {
		var classAccessors:Array = parseAccessorsByModifier(type, xml.accessor, true);
		var instanceAccessors:Array = parseAccessorsByModifier(type, xml.factory.accessor, false);
		return classAccessors.concat(instanceAccessors);
	}
	public static function parseMembers(memberClass:Class, members:XMLList, declaringType:Type, isStatic:Boolean):Array {
		var result:Array = [];
		for each (var m:XML in members) {
			var member:IMember = new memberClass(m.@name, Type.forName(m.@type), declaringType, isStatic);
			result.push(member);
		}
		return result;
	}
	private static function parseMethodsByModifier(type:Type, methodsXML:XMLList, isStatic:Boolean):Array {
		var result:Array = [];
		for each (var methodXML:XML in methodsXML) {
			var params:Array = [];
			for each(var paramXML:XML in methodXML.parameter) {
				var paramType:Type = Type.forName(paramXML.@type);
				var param:Parameter = new Parameter(paramXML.@index, paramType, paramXML.@optional);
				params.push(param);
			}
			result.push(new Method(type, methodXML.@name, isStatic, params, Type.forName(methodXML.@returnType)));
		}
		return result;
	}
	private static function parseAccessorsByModifier(type:Type, accessorsXML:XMLList, isStatic:Boolean):Array {
		var result:Array = [];
		for each (var accessorXML:XML in accessorsXML) {
			var accessor:Accessor = new Accessor(
										accessorXML.@name,
										AccessorAccess.fromString(accessorXML.@access),
										Type.forName(accessorXML.@type),
										type,
										isStatic);
			for each (var metaDataXML:XML in accessorXML.metadata) {
				accessor.metaData.push(new MetaData(metaDataXML.@name));
			}
			result.push(accessor);
		}
		return result;
	}
}