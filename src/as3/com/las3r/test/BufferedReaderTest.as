/**
* Copyright (c) Aemon Cannon. All rights reserved.
* The use and distribution terms for this software are covered by the
* Common Public License 1.0 (http://opensource.org/licenses/cpl.php)
* which can be found in the file CPL.TXT at the root of this distribution.
* By using this software in any fashion, you are agreeing to be bound by
* the terms of this license.
* You must not remove this notice, or any other, from this software.
*/


package com.las3r.test{
	import flexunit.framework.TestCase;
 	import flexunit.framework.TestSuite;
	import flash.utils.*;
	import com.las3r.jdk.io.StringReader;
	import com.las3r.jdk.io.BufferedReader;

	public class BufferedReaderTest extends RichTestCase {
		
		override public function setUp():void {
		}
		
		override public function tearDown():void {
		}

		public function testReadingAString():void{
			var str:String = "1234567890"
			var s:BufferedReader = new BufferedReader(new StringReader(str), 10);
			var result:String = "";
			for(var i:int = 0; i < 10; i++){
				result += String.fromCharCode(s.readOne());
			}
			assertTrue("read string should be the same", str == result);
		}


		public function testReadingStringBiggerThanBuffer():void{
			var str:String = "1234567890"
			var s:BufferedReader = new BufferedReader(new StringReader(str), 9);
			var result:String = "";
			for(var i:int = 0; i < 10; i++){
				result += String.fromCharCode(s.readOne());
			}
			assertTrue("read string should be the same", str == result);
		}

		public function testReadLine():void{
			var str:String = "hello\ndude"
			var s:BufferedReader = new BufferedReader(new StringReader(str));
			var result:String = s.readLine();
			assertTrue("result should be 'hello'", result == "hello");
			result = s.readLine();
			assertTrue("result should be 'dude'", result == "dude");
		}



	}

}