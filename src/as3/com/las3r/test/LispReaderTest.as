/**
* Copyright (c) Rich Hickey. All rights reserved.
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
	import com.las3r.runtime.*;
	import com.las3r.errors.*;
	import com.las3r.util.Util;
	import com.las3r.jdk.io.StringReader;
	import com.las3r.jdk.io.PushbackReader;

	public class LispReaderTest extends LAS3RTest {
		
		override public function setUp():void {
		}
		
		override public function tearDown():void {
		}


		public function testListOfSymbols():void{
			var rt:RT = new RT();
			var l:Object = readStr(rt, "(bird cat moose)");
			assertTrue("result is list", l is List);
			var list:List = List(l);
			assertTrue("should be 3 items in list", list.count() == 3);
		}


		public function testMap():void{
			var rt:RT = new RT();
			var m:Object = readStr(rt, "{ :bird 2 :cat 3 }");
			assertTrue("result is map", m is IMap);
			var map:IMap = IMap(m);
			assertTrue("should be 3 items in map", map.count() == 2);
			assertTrue("should be 2 at :bird", map.valAt(Keyword.intern2(rt, null, "bird")) == 2);
			assertTrue("should be 3 at :cat", map.valAt(Keyword.intern2(rt, null, "cat")) == 3);
		}


		public function testVector():void{
			var rt:RT = new RT();
			var v:Object = readStr(rt, "[ :bird :cat ]");
			assertTrue("result is vector", v is PersistentVector);
			var vec:PersistentVector = PersistentVector(v);
			assertTrue("should be 2 items in vec", vec.count() == 2);
			assertTrue("0th item should be :bird", vec.nth(0) == Keyword.intern2(rt, null, "bird"));
			assertTrue("1th item should be :cat", vec.nth(1) == Keyword.intern2(rt, null, "cat"));
		}


		public function testWhiteSpace():void{
			var rt:RT = new RT();
			var v:Object = readStr(rt, "   [ \n ,,,,:bird, \r,,,,, :cat ]     ");
			assertTrue("result is vector", v is PersistentVector);
			var vec:PersistentVector = PersistentVector(v);
			assertTrue("should be 2 items in vec", vec.count() == 2);
			assertTrue("0th item should be :bird", vec.nth(0) == Keyword.intern2(rt, null, "bird"));
			assertTrue("1th item should be :cat", vec.nth(1) == Keyword.intern2(rt, null, "cat"));
		}


		public function testReadNestedList():void{
			var rt:RT = new RT();
			var o:Object = readStr(rt, "(ape (dude (first 1 2 3)))");
			assertTrue("result is list", o is List);
			var list:List = List(o);
			assertTrue("should be 2 items in list", list.count() == 2);
			assertTrue("first item should be symbol 'ape'", list.first() == Symbol.intern1(rt, "ape"));
			assertTrue("second item should be a list", list.rest().first() is List);
		}


		public function testReadNestedListWithMap():void{
			var rt:RT = new RT();
			var o:Object = readStr(rt, "(ape {:cat 1})");
			assertTrue("result is list", o is List);
			var list:List = List(o);
			assertTrue("should be 2 items in list", list.count() == 2);
			assertTrue("first item should be symbol 'ape'", list.first() == Symbol.intern1(rt, "ape"));
			assertTrue("second item should be a map", list.rest().first() is IMap);
		}

		public function testNumbers():void{
			var rt:RT = new RT();
			assertTrue("numbers are equal", 1 == Number(readStr(rt, "+1")));
			assertTrue("numbers are equal", 1.0 == Number(readStr(rt, "1.0")));
			assertTrue("numbers are equal", 0.02 == Number(readStr(rt, "0.02")));
			assertTrue("numbers are equal", -232329 == Number(readStr(rt, "-232329")));
			assertTrue("numbers are equal", 0xFF0000 == Number(readStr(rt, "0xff0000")));
			assertTrue("numbers are equal", -0.04 == Number(readStr(rt, "-0.04")));
			assertTrue("numbers are equal", 0.5 == Number(readStr(rt, "1/2")));
			assertTrue("numbers are equal", -0.5 == Number(readStr(rt, "-1/2")));
			assertTrue("numbers are equal", 8 == Number(readStr(rt, "010")));
		}

		public function testSymbolAndKeywordInterning():void{
			var rt:RT = new RT();
			assertTrue("objects are equal", readStr(rt, ":dude") == readStr(rt, ":dude"));
			assertTrue("objects are equal", readStr(rt, ":happy-go-lucky") == readStr(rt, ":happy-go-lucky"));
			assertTrue("objects are equal", readStr(rt, "hello-out-there") == readStr(rt, "hello-out-there"));
			assertTrue("objects are NOT equal", readStr(rt, ":hello-out-there") != readStr(rt, "hello-out-there"));

			assertTrue("symbol should have correct namespace", readStr(rt, "dude/horse").getNamespace() == "dude");
			assertTrue("symbol should have correct name", readStr(rt, "dude/horse").getName() == "horse");
		}

		public function testQuote():void{
			var rt:RT = new RT();
			assertTrue("objects are equal", Util.equal(readStr(rt, "'(a b c)"), readStr(rt, "(quote (a b c))")));
		}

		public function testRegexps():void{
			var rt:RT = new RT();
			assertTrue("object is regexp", readStr(rt, "#\"hello\"") is RegExp);
			var r:RegExp = RegExp(readStr(rt, "#\"hello\""));
			assertTrue("must function corectly", "hello".match(r) != null);
		}


		public function testCharacterLiterals():void{
			var rt:RT = new RT();
			assertTrue("chars should be equal", readStr(rt, "\\a") == "a");
			assertTrue("chars should be equal", readStr(rt, "\\newline") == "\n");
			assertTrue("chars should be equal", readStr(rt, "\\tab") == "\t");
			assertTrue("chars should be equal", readStr(rt, "\\space") == " ");
			assertTrue("chars should be equal", readStr(rt, "\\backspace") == "\b");
			assertTrue("chars should be equal", readStr(rt, "\\u005c") == "\\");
		}


		public function testSomeRandomTokens():void{
			var rt:RT = new RT();
			assertTrue("should be null", readStr(rt, "nil") === null);
			assertTrue("should be false", readStr(rt, "false") === false);
			assertTrue("should be true", readStr(rt, "true") === true);
		}


		public function testUnterminated():void{
			var rt:RT = new RT();

			assertThrows("should throw exception", function(){
					readStr(rt, "(hello out ther (dude)");	
				});

			assertThrows("should throw exception", function(){
					readStr(rt, "(hello out ther {dude");
				});

			assertThrows("should throw exception", function(){
					readStr(rt, "[hello out ther");
				});

		}

		public function testSyntaxQuoteString():void{
			var rt:RT = new RT();
			var a:Object = readStr(rt, "`\"hello\"");
			var b:Object = readStr(rt, "\"hello\"");
			assertTrue("objects are equal", Util.equal(a, b));
		}


	}

}