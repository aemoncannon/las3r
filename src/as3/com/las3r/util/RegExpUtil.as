package com.las3r.util
{
	public class RegExpUtil
	{
		// Returns the RegExp's flags as a string.
		public static function flags(re:RegExp) {
			var ret:String = "";

			if(re.global) ret += "g";
			if(re.ignoreCase) ret += "i";
 			if(re.dotall) ret += "s";
 			if(re.multiline) ret += "m";
 			if(re.extended) ret += "x";

			return ret;
		}
	}
}