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
	import com.las3r.jdk.io.FilterReader;

	public class FilterReaderTest extends RichTestCase {
		
		override public function setUp():void {
		}
		
		override public function tearDown():void {
		}

		public function testCreate():void{
			var s:FilterReader = new FilterReader(new StringReader("hello"));
		}

		public function testReadStringCharByChar():void{
			var s:FilterReader = new FilterReader(new StringReader("hello"));
			assertTrue("first character should be 'h'", String.fromCharCode(s.readOne()) == "h");
			assertTrue("next character should be 'e'", String.fromCharCode(s.readOne()) == "e");
			assertTrue("next character should be 'l'", String.fromCharCode(s.readOne()) == "l");
			assertTrue("next character should be 'l'", String.fromCharCode(s.readOne()) == "l");
			assertTrue("next character should be 'o'", String.fromCharCode(s.readOne()) == "o");
			assertTrue("next character should be -1", s.readOne() == -1);
		}


		public function testReadStringIntoArray():void{
			var s:FilterReader = new FilterReader(new StringReader("hello"));
			var a:Array = new Array(20);
			assertTrue("return value should be 5", s.readIntoArray(a) == 5);
			assertTrue("first character should be 'h'",String.fromCharCode(a[0]) == "h");
			assertTrue("next character should be 'e'", String.fromCharCode(a[1]) == "e");
			assertTrue("next character should be 'l'", String.fromCharCode(a[2]) == "l");
			assertTrue("next character should be 'l'", String.fromCharCode(a[3]) == "l");
			assertTrue("next character should be 'o'", String.fromCharCode(a[4]) == "o");
			assertTrue("next character should be null", !a[5]);
			assertTrue("return value should be -1", s.readIntoArray(a) == -1);
		}

		public function testSkip():void{
			var s:FilterReader = new FilterReader(new StringReader("hello"));
			assertTrue("first character should be 'h'", String.fromCharCode(s.readOne()) == "h");
			assertTrue("should return 1, one char skipped", s.skip(1) == 1);			
			assertTrue("next character should be 'l'", String.fromCharCode(s.readOne()) == "l");
			assertTrue("should return 2, two chars skipped", s.skip(2) == 2);
			assertTrue("next character should be -1", s.readOne() == -1);
		}

		public function testMarkAndReset():void{
			var s:FilterReader = new FilterReader(new StringReader("hello"));
			assertTrue("first character should be 'h'", String.fromCharCode(s.readOne()) == "h");
			s.mark(0);
			assertTrue("next character should be 'e'", String.fromCharCode(s.readOne()) == "e");
			assertTrue("next character should be 'l'", String.fromCharCode(s.readOne()) == "l");
			assertTrue("next character should be 'l'", String.fromCharCode(s.readOne()) == "l");
			s.reset();
			assertTrue("next character should be 'e'", String.fromCharCode(s.readOne()) == "e");
			assertTrue("next character should be 'l'", String.fromCharCode(s.readOne()) == "l");
			assertTrue("next character should be 'l'", String.fromCharCode(s.readOne()) == "l");
			assertTrue("next character should be 'o'", String.fromCharCode(s.readOne()) == "o");
			assertTrue("next character should be -1", s.readOne() == -1);
		}

	}

}