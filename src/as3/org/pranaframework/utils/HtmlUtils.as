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
	 * @since 2008-01-23
	 * 
	 * Contains utility methods for working with html.
	 */
	public class HtmlUtils{
		/** string used for newline (&lt;BR&gt; or \n work best) */
		public static const BR:String = "<BR>"; 
		/** string used for tab (&lt;TAB&gt; or \t work best) */
		public static const TAB:String = "<TAB>"; 
		
		/**
		 * parseTables<br>
		 * Parses tables with the Parse class and outputs String fit for use as htmlText.<br>
		 * No support for nested tables.<br>
		 * Ignores errors thrown by Parse.<br>
		 * 
		 * @param html String with &lt;table&gt; notation
		 * @return String with &lt;TEXTFORMAT&gt; notation
		 */
		public static function parseTables(html:String):String{
			var result:String;
			var parsedHtml:Parse;
			try{
				result = "";
				parsedHtml = new Parse(html, null);
			}catch(error:Error){
				//an error occured, ignore it and return the input
				trace(error.message);
				result = html;
				parsedHtml = null;
			}
			for(var table:Parse = parsedHtml; table != null; table = table.more){
				result += table.leader;
				result += "<TEXTFORMAT TABSTOPS=\"";
				var tabPosition:int = 0;
				for(var td:Parse = table.parts.parts; td != null; td = td.more){
					tabPosition += td.width();
					result += tabPosition;
					if(td.more != null){
						result += ",";
					}
				}
				result += "\">";
				
				for(var tr:Parse = table.parts; tr != null; tr = tr.more){
					for(var td2:Parse = tr.parts; td2 != null; td2 = td2.more){
						result += td2.body;
						if(td2.more != null){
							result += TAB;
						}
					}
					if(tr.more != null){
						result += BR;
					}
				}
				result += "</TEXTFORMAT>";
				if(table.more== null){
					result += table.trailer;
				}
			}
			return result;
		}
		
	}
}
