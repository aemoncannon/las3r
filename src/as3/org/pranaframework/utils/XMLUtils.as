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
	import flash.xml.XMLNode;
	import flash.xml.XMLNodeType;
	
	
	/**
	 * Contains utilities for working with XML objects.
	 * 
	 * @author Christophe Herreman
	 */
	public class XMLUtils {
		
		public static const ELEMENT_NODE_KIND:String = "element";
		public static const TEXT_NODE_KIND:String = "text";
		
		/**
		 * Creates a CDATA section for the given data string.
		 * Use this method if you need to create a CDATA section with a binding
		 * expression in a literal XML declaration
		 * 
		 * @param data the data string to create a CDATA section from.
		 * @return a CDATA section for the data
		 */
		public static function cdata(data:String):XML {
			var result:XML = new XML("<![CDATA[" + data + "]]>");
			return result;
		}
		
		/**
		 * Returns if the given xml node is an element node.
		 */
		public static function isElementNode(xml:XML):Boolean {
			return (ELEMENT_NODE_KIND == xml.nodeKind());
		}
		
		/**
		 * Returns if the given xml node is a text node.
		 */
		public static function isTextNode(xml:XML):Boolean {
			return (TEXT_NODE_KIND == xml.nodeKind());
		}
				
		/**
		 * Converts an attribute to a node.
		 * 
		 * @param xml the xml node that contains the attribute
		 * @param attribute the name of the attribute that will be converted to a node
		 * @return the passed in xml node with the specified attribute converted to a node
		 */
		public static function convertAttributeToNode(xml:XML, attribute:String):XML {
			var attributes:XMLList = xml.attribute(attribute);
			if (attributes) {
				if (attributes[0] != undefined) {
					var node:XMLNode = new XMLNode(XMLNodeType.ELEMENT_NODE, attribute);
					var value:XMLNode = new XMLNode(XMLNodeType.TEXT_NODE, attributes[0].toString());
					node.appendChild(value);
					xml.appendChild(node);
					delete attributes[0];
				}
			}
			return xml;
		}
		

	}
}