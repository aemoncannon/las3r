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
	
	import flash.system.ApplicationDomain;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getQualifiedSuperclassName;
	
	import org.pranaframework.errors.ClassNotFoundError;
	
	/**
	 * Provides utilities for working with <code>Class</code> objects.
	 * 
	 * @author Christophe Herreman
	 */
	public class ClassUtils {
		
		private static const PACKAGE_CLASS_SEPARATOR:String = "::";
		
		/**
		 * Returns a <code>Class</code> object that corresponds with the given
		 * instance. If no correspoding class was found, a
		 * <code>ClassNotFoundError</code> will be thrown.
		 * 
		 * @param instance the instance from which to return the class
		 * @param applicationDomain the optional applicationdomain where the instance's class resides
		 * 
		 * @return the <code>Class</code> that corresponds with the given instance
		 * 
		 * @see org.pranaframework.errors.ClassNotFoundError
		 */
		public static function forInstance(instance:*, applicationDomain:ApplicationDomain = null):Class {		
			var className:String = ObjectUtils.getFullQualifiedClassName(instance);
			return forName(className, applicationDomain);
		}
		
		/**
		 * Returns a <code>Class</code> object that corresponds with the given
		 * name. If no correspoding class was found in the applicationdomain tree, a
		 * <code>ClassNotFoundError</code> will be thrown.
		 * 
		 * @param name the name from which to return the class
		 * @param applicationDomain the optional applicationdomain where the instance's class resides
		 * 
		 * @return the <code>Class</code> that corresponds with the given name
		 * 
		 * @see org.pranaframework.errors.ClassNotFoundError
		 */
		public static function forName(name:String, applicationDomain:ApplicationDomain = null):Class {
			var result:Class;
			
			if (!applicationDomain) {
				applicationDomain = ApplicationDomain.currentDomain;
			}
			
			while (!applicationDomain.hasDefinition(name)) {
				if (applicationDomain.parentDomain) {
					applicationDomain = applicationDomain.parentDomain;
				}
				else {
					break;
				}
			}
			
			try {
				result = applicationDomain.getDefinition(name) as Class;
			}
			catch(e:ReferenceError) {
				throw new ClassNotFoundError("A class with the name '" + name + "' could not be found.");
			}
			return result;
		}
		
		/**
		 * Returns the name of the given class.
		 * 
		 * @param clazz the class to get the name from
		 * 
		 * @return the name of the class
		 */
		public static function getName(clazz:Class):String {
			Assert.notNull(clazz, "The clazz cannot be null");
			return getNameFromFullyQualifiedName(getFullyQualifiedName(clazz));
		}
		
		/**
		 * Returns the name of the class or interface, based on the given fully
		 * qualified class or interface name.
		 * 
		 * @param fullyQualifiedName the fully qualified name of the class or interface
		 * 
		 * @return the name of the class or interface
		 */
		public static function getNameFromFullyQualifiedName(fullyQualifiedName:String):String {
			var result:String = "";
			var startIndex:int = fullyQualifiedName.indexOf(PACKAGE_CLASS_SEPARATOR);
			if (startIndex == -1)
				result = fullyQualifiedName;
			else
				result = fullyQualifiedName.substring(startIndex + PACKAGE_CLASS_SEPARATOR.length, fullyQualifiedName.length);
			return result;
		}
		
		/**
		 * Returns the fully qualified name of the given class.
		 * 
		 * @param clazz the class to get the name from
		 * @param replaceColons whether the double colons "::" should be replaced by a dot "."
		 * 						the default is false
		 * 
		 * @return the fully qualified name of the class
		 */
		public static function getFullyQualifiedName(clazz:Class, replaceColons:Boolean = false):String {
			Assert.notNull(clazz, "The clazz cannot be null");
			var result:String = getQualifiedClassName(clazz);
			if (replaceColons)
				result = convertFullyQualifiedName(result);
			return result;
		}
		
		/**
		 * Returns whether the passed in Class object is a subclass of the
		 * passed in parent Class.
		 */
		public static function isSubclassOf(clazz:Class, parentClass:Class):Boolean {
			Assert.notNull(clazz, "The clazz argument must no be null");
			Assert.notNull(parentClass, "The parentClass argument must not be null");
			var classDescription:XML = MetadataUtils.getFromObject(clazz);
			var parentName:String = getQualifiedClassName(parentClass);
			return (classDescription.factory.extendsClass.(@type == parentName).length() != 0);
		}
		
		/**
		 * Returns the class that the passed in clazz extends. If no super class
		 * was found, in case of Object, null is returned.
		 * 
		 * @param clazz the class to get the super class from
		 * 
		 * @returns the super class or null if no parent class was found
		 */
		public static function getSuperClass(clazz:Class):Class {
			Assert.notNull(clazz, "The clazz argument must no be null");
			var result:Class;
			var classDescription:XML = MetadataUtils.getFromObject(clazz);
			var superClasses:XMLList = classDescription.factory.extendsClass;
			if (superClasses.length() > 0)
				result = ClassUtils.forName(superClasses[0].@type);
			return result;
		}
		
		/**
		 * Returns the name of the given class' superclass.
		 * 
		 * @param clazz the class to get the name of its superclass' from
		 * 
		 * @return the name of the class' superclass
		 */
		public static function getSuperClassName(clazz:Class):String {
			Assert.notNull(clazz, "The clazz cannot be null");
			var fullyQualifiedName:String = getFullyQualifiedSuperClassName(clazz);
			var index:int = fullyQualifiedName.indexOf(PACKAGE_CLASS_SEPARATOR) + PACKAGE_CLASS_SEPARATOR.length;
			return fullyQualifiedName.substring(index, fullyQualifiedName.length);
		}
		
		/**
		 * Returns the fully qualified name of the given class' superclass.
		 * 
		 * @param clazz the class to get its superclass' name from
		 * @param replaceColons whether the double colons "::" should be replaced by a dot "."
		 * 						the default is false
		 * 
		 * @return the fully qualified name of the class' superclass
		 */
		public static function getFullyQualifiedSuperClassName(clazz:Class, replaceColons:Boolean = false):String {
			Assert.notNull(clazz, "The clazz cannot be null");
			var result:String = getQualifiedSuperclassName(clazz);
			if (replaceColons)
				result = convertFullyQualifiedName(result);
			return result;
		}
		
		/**
		 * Returns whether the passed in <code>Class</code> object implements
		 * the given interface.
		 * 
		 * @param clazz the class to check for an implemented interface
		 * @param interfaze the interface that the clazz argument should implement
		 * 
		 * @return true if the clazz object implements the given interface; false if not
		 */
		public static function isImplementationOf(clazz:Class, interfaze:Class):Boolean {
			var result:Boolean;
			if (clazz == null) {
				result = false;
			}
			else {
				var classDescription:XML = MetadataUtils.getFromObject(clazz);
				result = (classDescription.factory.implementsInterface.(@type == getQualifiedClassName(interfaze)).length() != 0);
			}
			return result;
		}
		
		/**
		 * Returns an array of all interface names that the given class implements.
		 */
		public static function getImplementedInterfaceNames(clazz:Class):Array {
			var result:Array = getFullyQualifiedImplementedInterfaceNames(clazz);
			for (var i:int = 0; i<result.length; i++) {
				result[i] = getNameFromFullyQualifiedName(result[i]);
			}
			return result;
		}
		
		/**
		 * Returns an array of all fully qualified interface names that the
		 * given class implements.
		 */
		public static function getFullyQualifiedImplementedInterfaceNames(clazz:Class, replaceColons:Boolean = false):Array {
			var result:Array = [];
			var classDescription:XML = MetadataUtils.getFromObject(clazz);
			var interfacesDescription:XMLList = classDescription.factory.implementsInterface;
			
			if (interfacesDescription) {
				var numInterfaces:int = interfacesDescription.length();
				for (var i:int = 0; i<numInterfaces; i++) {
					var fullyQualifiedInterfaceName:String = interfacesDescription[i].@type.toString();
					if (replaceColons)
						fullyQualifiedInterfaceName = convertFullyQualifiedName(fullyQualifiedInterfaceName);
					result.push(fullyQualifiedInterfaceName);
				}
			}
			return result;
		}
		
		/**
		 * Returns an array of all interface names that the given class implements.
		 */
		public static function getImplementedInterfaces(clazz:Class):Array {
			var result:Array = getFullyQualifiedImplementedInterfaceNames(clazz);
			for (var i:int = 0; i<result.length; i++) {
				result[i] = getDefinitionByName(result[i]);
			}
			return result;
		}
		
		/**
		 * Creates an instance of the given class and passes the arguments to
		 * the constructor.
		 * 
		 * TODO find a generic solution for this. Currently we support constructors
		 * with a maximum of 10 arguments.
		 * 
		 * @param clazz the class from which an instance will be created
		 * @param args the arguments that need to be passed to the constructor
		 */
		public static function newInstance(clazz:Class, args:Array = null):* {
			var result:*;
			var a:Array = (args == null) ? [] : args;
			
			switch (a.length) {
				case 1:
					result = new clazz(a[0]);
					break;
				case 2:
					result = new clazz(a[0], a[1]);
					break;
				case 3:
					result = new clazz(a[0], a[1], a[2]);
					break;
				case 4:
					result = new clazz(a[0], a[1], a[2], a[3]);
					break;
				case 5:
					result = new clazz(a[0], a[1], a[2], a[3], a[4]);
					break;
				case 6:
					result = new clazz(a[0], a[1], a[2], a[3], a[4], a[5]);
					break;
				case 7:
					result = new clazz(a[0], a[1], a[2], a[3], a[4], a[5], a[6]);
					break;
				case 8:
					result = new clazz(a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7]);
					break;
				case 9:
					result = new clazz(a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7], a[8]);
					break;
				case 10:
					result = new clazz(a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7], a[8], a[9]);
					break;
				default:
					result = new clazz();	
			}
			
			return result;
		}
		
		/**
		 * Converts the double colon (::) in a fully qualified class name to a dot (.)
		 */
		public static function convertFullyQualifiedName(className:String):String {
			return className.replace(PACKAGE_CLASS_SEPARATOR, ".");
		}
		
	}
}