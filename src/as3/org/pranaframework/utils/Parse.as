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
package org.pranaframework.utils{
	
	import mx.utils.StringUtil;
	
	/**
	 * @author Kristof Neirynck
	 * @since 2008-01-22
	 * @url http://fit.c2.com/wiki.cgi?ParsingTables
	 * 
	 * Helper class for HtmlUtil.<br>
	 * A port from the Fit framework.
	 */
	public class Parse{
		
		/** text before the startTag */
		public var leader:String;
		/** startTag (contains attributes) */
		public var tag:String;
		/** text inside the td (or null if it isn't a td) */
		public var body:String;
		/** endTag */
		public var end:String;
		/** text after the endTag */
		public var trailer:String;
		
		/** nextsibling */
		public var more:Parse;
		/** first child */
		public var parts:Parse;
		
		/** default tagnames [&quot;table&quot;, &quot;tr&quot;, &quot;td&quot;] */
		public static const TAGS:Array = ["table", "tr", "td"];
		
		/**
		 * Parse constructor<br>
		 * Every table, tr and td is a Parse element<br>
		 * 
		 * @param String text input
		 * @param Array tags optional default Parse.TAGS (use null to get default)
		 * @param int level optional default 0
		 * @param int offset optional default 0
		 */
		public function Parse(text:String, tags:Array, level:int = 0, offset:int = 0){
			if(tags == null){tags = Parse.TAGS;}
			var lc:String = text.toLowerCase();
			var startTag:int = lc.indexOf("<"+tags[level]);
			var endTag:int = lc.indexOf(">", startTag) + 1;
			var startEnd:int = lc.indexOf("</"+tags[level], endTag);
			var endEnd:int = lc.indexOf(">", startEnd) + 1;
			var startMore:int = lc.indexOf("<"+tags[level], endEnd);
			
			//trace(startTag + ", " + endTag + ", " + startEnd + ", " + endEnd + ", " + startMore);
			
			if(startTag<0 || endTag<0 || startEnd<0 || endEnd<0){
				throw new ParseError("Can't find tag: "+tags[level], offset);
			}
			
			leader  = text.substring(0, startTag);
			tag     = text.substring(startTag, endTag);
			body    = text.substring(endTag, startEnd);
			end     = text.substring(startEnd, endEnd);
			trailer = text.substring(endEnd);
			
			//trace(leader + ", " + tag + ", " + body + ", " + end + ", " + trailer);
			
			if(level + 1 < tags.length){
				parts = new Parse(body, tags, level+1, offset+endTag);
				body = null;
			}
			
			// FIX >= 0 gives stack overflow
			if(startMore > 0){
				more = new Parse(trailer, tags, level, offset+endEnd);
				trailer = null;
			}
		}
		
		/**
		 * @return exactly the same string as the input
		 */
		public function toString():String{
			var result:String = leader + tag;
			if(parts != null){
				result += parts.toString();
			}else{
				result += body.toString();
			}
			result += end;
			if(more != null){
				result += more.toString();
			}else{
				result += trailer;
			}
			return result;
		}
		
		/**
		 * width attribute value or 0 if not found
		 */
		public function width():int{
			var result:int = parseInt(getAttribute("width").replace(/[^0-9]+.*/, ""));
			if(isNaN(result)){
				result = 0;
			}
			return result;
		}
		
		/**
		 * last element on same depth<br>
		 * td.last returns the last td from the same tr  
		 */
		public function last():Parse{
			return more == null ? this : more.last();
		}
		
		/**
		 * Count elements on same depth.<br>
		 * Doesn't count those before this one.
		 */
	    public function size():int {
	        return more==null ? 1 : more.size()+1;
	    }
		
		/**
		 * Get first leaf child.
		 */		
	    public function leaf():Parse {
	        return parts==null ? this : parts.leaf();
	    }
		
		/**
		 * Get sibling or child by index.<br>
		 * 
		 * @param i index
		 * @param j optional index one level deeper
		 * @param k optional index two levels deeper
		 * @return sibling or child
		 */
	    public function at(i:int, j:int = -1, k:int = -1):Parse {
			if(j != -1){
				if(k != -1){
					return at(i).parts.at(j).parts.at(k);
				}else{
					return at(i).parts.at(j);
				}
			}else{
				return i==0 || more==null ? this : more.at(i-1);
			}
	    }
	    
		/**
		 * attribute value by name
		 */
		public function getAttribute(name:String):String{
			var regexpBefore:RegExp = new RegExp(".* "+name+"\\s*=\\s*", "");
			var quotedValue:String = tag.replace(regexpBefore, "");
			var value:String = quotedValue;
			var quote:String = quotedValue.charAt(0);
			if(quote == "\"" || quote == "'"){
				if(value.indexOf(quote, 1) != -1){
					value = value.substring(1, value.indexOf(quote, 1));
				}else{
					value = value.substr(1);
					value = value.replace(/[\s"'].*/, "");
				}
			}else{
				value = StringUtils.trim(value);
				value = value.replace(/\s.*/, "");
			}
			return value;
		}
		
		/**
		 * Unformat, unescape and trim String value
		 */
		public function text():String {
			return Parse.parseText(this.toString());
		}
		
		/**
		 * Unformat, unescape and trim a String.
		 */
		public static function parseText(s:String):String {
	        return StringUtils.trim(Parse.unescape(Parse.unformat(s)));
	    }
		
	    /**
	     * Removes all html tags from a string
	     */
	    public static function unformat(s:String):String {
	        var i:int=0, j:int;
	        while ((i=s.indexOf('<',i))>=0) {
	            if ((j=s.indexOf('>',i+1))>0) {
	                s = s.substring(0,i) + s.substring(j+1);
	            } 
	            else {
	            	break;
	            }
	        }
	        return s;
	    }
		
		/**
		 * Unescape all entities in a string.
		 */
	    public static function unescape(s:String):String {
	        var i:int=-1, j:int;
	        while ((i=s.indexOf('&',i+1))>=0) {
	            if ((j=s.indexOf(';',i+1))>0) {
	                var from:String = s.substring(i+1, j).toLowerCase();
	                var to:String = null;
	                if ((to=replacement(from)) != null) {
	                    s = s.substring(0,i) + to + s.substring(j+1);
	                }
	            }
	        }
	        return s;
	    }
	    
		/**
		 * Unescape an entity.
		 */
	    public static function replacement(from:String):String {
	    	var result:String = null;
	    	switch(from){
	    		case "lt": result = "<"; break;
	    		case "gt": result = ">"; break;
	    		case "amp": result = "&"; break;
	    		case "nbsp": result = " "; break;
	    		default: result = null; 
	    	}
	    	return result;
	    }
	}
}