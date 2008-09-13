/**
 * Hex
 * 
 * Utility class to convert Hex strings to ByteArray or String types.
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.util
{
	import flash.utils.ByteArray;
	
	public class Hex
	{
		/**
		 * Support straight hex, or colon-laced hex.
		 * (that means 23:03:0e:f0, but *NOT* 23:3:e:f0)
		 * Whitespace characters are ignored.
		 */
		public static function toArray(hex:String):ByteArray {
			hex = hex.replace(/\s|:/gm,'');
			var a:ByteArray = new ByteArray;
			if (hex.length&1==1) hex="0"+hex;
			for (var i:uint=0;i<hex.length;i+=2) {
				a[i/2] = parseInt(hex.substr(i,2),16);
			}
			return a;
		}
		
		public static function fromArray(array:ByteArray, colons:Boolean=false):String {
			var s:String = "";
			for (var i:uint=0;i<array.length;i++) {
				s+=("0"+array[i].toString(16)).substr(-2,2);
				if (colons) {
					if (i<array.length-1) s+=":";
				}
			}
			return s;
		}
		
		public static function dump(array:ByteArray):String {
			var s:String = "";
			var a:String = "";
			for (var i:uint=0;i<array.length;i++) {
				if (i%16==0) { // dump offset
					s+= ("00000000"+i.toString(16)).substr(-8,8)+" ";
				}
				if (i%8==0) {
					s+= " ";
				}
				var v:int = array[i];
				s+=("0"+v.toString(16)).substr(-2,2)+" ";
				a+=(v<32||v>126)?".":String.fromCharCode(v);
				if (((i+1)%16==0)||(i==array.length-1)) {
					s+= " |"+a+"|\n";
					a="";
				}
			}
			return s;
		}
		
		public static function undump(str:String):ByteArray {
			// rules:
			//  - ignore the first 10 bytes of every line
			//  - parse hex digits on the line until "|" is met
			// hm. yeah. that's it.
			var bytes:ByteArray = new ByteArray;
			var lines:Array = str.split(/(\n|\r)+/);
			while (lines.length>0&&lines[0].length>0) {
				var stuff:Array = lines.shift().substr(10).split("  |")[0].split(/\s+/);
				while (stuff.length>0&&stuff[0].length>0) {
					bytes.writeByte(parseInt(stuff.shift(), 16));
				}
			}
			bytes.position = 0;
			return bytes;
		}
		
		/**
		 * 
		 * @param hex
		 * @return a UTF-8 string decoded from hex
		 * 
		 */
		public static function toString(hex:String):String {
			var a:ByteArray = toArray(hex);
			return a.readUTFBytes(a.length);
		}
		
		
		/**
		 * 
		 * @param str
		 * @return a hex string encoded from the UTF-8 string str
		 * 
		 */
		public static function fromString(str:String, colons:Boolean=false):String {
			var a:ByteArray = new ByteArray;
			a.writeUTFBytes(str);
			return fromArray(a, colons);
		}
		
		
	}
}