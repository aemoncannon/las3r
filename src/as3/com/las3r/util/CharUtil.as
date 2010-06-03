/**
* Copyright (c) Rich Hickey. All rights reserved.
* Copyright (c) Aemon Cannon. All rights reserved.
* The use and distribution terms for this software are covered by the
* Common Public License 1.0 (http://opensource.org/licenses/cpl.php)
* which can be found in the file CPL.TXT at the root of this distribution.
* By using this software in any fashion, you are agreeing to be bound by
* the terms of this license.
* You must not remove this notice, or any other, from this software.
*/


package com.las3r.util
{
	public class CharUtil
	{
		public static var LESS_THAN:int = "<".charCodeAt(0);
		public static var EQUALS:int = "=".charCodeAt(0);
		public static var SPACE:int = " ".charCodeAt(0);
		public static var LF:int = "\n".charCodeAt(0);
		public static var CR:int = "\r".charCodeAt(0);
		public static var TAB:int = "\t".charCodeAt(0);
		public static var BACKSPACE:int = "\b".charCodeAt(0);
		public static var FORM_FEED:int = "\f".charCodeAt(0);
		public static var RETURN:int = "\r".charCodeAt(0);
		public static var COMMA:int = ",".charCodeAt(0);
		public static var DIG_0:int = "0".charCodeAt(0);
		public static var DIG_1:int = "1".charCodeAt(0);
		public static var DIG_2:int = "2".charCodeAt(0);
		public static var DIG_3:int = "3".charCodeAt(0);
		public static var DIG_4:int = "4".charCodeAt(0);
		public static var DIG_5:int = "5".charCodeAt(0);
		public static var DIG_6:int = "6".charCodeAt(0)
		public static var DIG_7:int = "7".charCodeAt(0);
		public static var DIG_8:int = "8".charCodeAt(0);
		public static var DIG_9:int = "9".charCodeAt(0);
		public static var PLUS:int = "+".charCodeAt(0);
		public static var MINUS:int = "-".charCodeAt(0);
		public static var COLON:int = ":".charCodeAt(0);
		public static var DOUBLE_QUOTE:int = "\"".charCodeAt(0);
		public static var SEMICOLON:int = ";".charCodeAt(0);
		public static var SINGLE_QUOTE:int = "\'".charCodeAt(0);
		public static var AT:int = "@".charCodeAt(0);
		public static var CARROT:int = "^".charCodeAt(0);
		public static var BACKTICK:int = "`".charCodeAt(0);
		public static var TILDE:int = "~".charCodeAt(0);
		public static var LPAREN:int = "(".charCodeAt(0);
		public static var RPAREN:int = ")".charCodeAt(0);
		public static var LBRACK:int = "[".charCodeAt(0);
		public static var RBRACK:int = "]".charCodeAt(0);
		public static var LBRACE:int = "{".charCodeAt(0);
		public static var RBRACE:int = "}".charCodeAt(0);
		public static var BACK_SLASH:int = "\\".charCodeAt(0);
		public static var PERCENT:int = "%".charCodeAt(0);
		public static var POUND:int = "#".charCodeAt(0);
		public static var UNDERSCORE:int = "_".charCodeAt(0);
		public static var T:int = "t".charCodeAt(0);
		public static var R:int = "r".charCodeAt(0);
		public static var N:int = "n".charCodeAt(0);
		public static var B:int = "b".charCodeAt(0);
		public static var F:int = "f".charCodeAt(0);
		public static var U:int = "u".charCodeAt(0);

		public static function isWhitespace(c:int):Boolean{
			return (c == SPACE || c == LF || c == CR || c == TAB || c == BACKSPACE || c == FORM_FEED || c == COMMA);
		}

		public static function isDigit(c:int):Boolean{
			return (
				c == DIG_0 || 
				c == DIG_1 || 
				c == DIG_2 || 
				c == DIG_3 || 
				c == DIG_4 || 
				c == DIG_5 || 
				c == DIG_6 || 
				c == DIG_7 || 
				c == DIG_8 || 
				c == DIG_9
			);

		}

		public static function digit(c:int, base:int):int{
			return parseInt(String.fromCharCode(c), base);
		}
		
	}
}