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
	import com.las3r.util.Util;
	import com.las3r.runtime.RT;
	import com.las3r.runtime.PersistentHashMap;
	import com.las3r.runtime.IMap;
	import com.las3r.runtime.ISeq;
	import com.las3r.runtime.MapEntry;

	public class MapTest extends LAS3RTest {
		
		override public function setUp():void {
		}
		
		override public function tearDown():void {
		}

		public function testSimple():void{
			var m:IMap = PersistentHashMap.createFromMany(1, 1, 2, 2, 3, 3);
 			assertTrue("1 should be 1", m.valAt(1) == 1);
 			assertTrue("2 should be 2", m.valAt(2) == 2);
 			assertTrue("3 should be 3", m.valAt(3) == 3);
 			assertTrue("count of map should be 3", m.count() == 3);
 			m = m.assoc(5, 5);
 			assertTrue("5 should be 5", m.valAt(5) == 5);
 			assertTrue("6 should be default val", m.valAt(6, "horse") == "horse");
		}

		public function testStringKeys():void{
			var m:IMap = PersistentHashMap.createFromMany("one", 1, "two", 2, "three", 3);
 			assertTrue("1 should be 1", m.valAt("one") == 1);
 			assertTrue("2 should be 2", m.valAt("two") == 2);
 			assertTrue("3 should be 3", m.valAt("three") == 3);
 			assertTrue("count of map should be 3", m.count() == 3);
 			m = m.assoc("five", 5);
 			assertTrue("5 should be 5", m.valAt("five") == 5);
 			assertTrue("6 should be default val", m.valAt("six", "horse") == "horse");
		}

		public function testKeywordKeys():void{
			var rt:RT = new RT();
			var m:IMap = PersistentHashMap.createFromMany(key1(rt, "one"), 1, key1(rt, "two"), 2, key1(rt, "three"), 3);
 			assertTrue("1 should be 1", m.valAt(key1(rt, "one")) == 1);
 			assertTrue("2 should be 2", m.valAt(key1(rt, "two")) == 2);
 			assertTrue("3 should be 3", m.valAt(key1(rt, "three")) == 3);
 			assertTrue("count of map should be 3", m.count() == 3);
 			m = m.assoc(key1(rt, "five"), 5);
 			assertTrue("5 should be 5", m.valAt(key1(rt, "five")) == 5);
 			assertTrue("6 should be default val", m.valAt(key1(rt, "six"), "horse") == "horse");
		}

		public function testNonIHashableObjectKeys():void{
			var rt:RT = new RT();
			var a:Object = {};
			var b:Object = {};
			var c:Object = {};
			var m:IMap = PersistentHashMap.createFromMany(a, 1, b, 2, c, 3);
 			assertTrue("a should be 1", m.valAt(a) == 1);
 			assertTrue("b should be 2", m.valAt(b) == 2);
 			assertTrue("c should be 3", m.valAt(c) == 3);
 			assertTrue("count of map should be 3", m.count() == 3);
		}


		public function testSequencing():void{
			var m:IMap = PersistentHashMap.createFromMany("one", 1, "two", 2, "three", 3);
			var s:ISeq = m.seq();

			var first:Object = s.first();
			assertTrue("first should be a MapEntry of one and 1", first is MapEntry);
			assertTrue("first should be a MapEntry of one and 1", first.key == "one");
			assertTrue("first should be a MapEntry of one and 1", first.value == 1);

			var second:Object = s.rest().first();
			assertTrue("second should be a MapEntry of one and 1", second is MapEntry);
			assertTrue("second should be a MapEntry of one and 1", second.key == "two");
			assertTrue("second should be a MapEntry of one and 1", second.value == 2);

			var third:Object = s.rest().rest().first();
			assertTrue("third should be a MapEntry of one and 1", third is MapEntry);
			assertTrue("third should be a MapEntry of one and 1", third.key == "three");
			assertTrue("third should be a MapEntry of one and 1", third.value == 3);

			assertNull("should be at the end", s.rest().rest().rest());
		}

		public function testSequencingNonHashables():void{
			var a:Object = {};
			var b:Object = {};
			var c:Object = {};
			var m:IMap = PersistentHashMap.createFromMany(a, 1, b, 2, c, 3);
			var s:ISeq = m.seq();

			var first:Object = s.first();
			assertTrue("first should be a MapEntry of a and 1", first is MapEntry);
			assertTrue("first should be a MapEntry of a and 1", first.key == a);
			assertTrue("first should be a MapEntry of a and 1", first.value == 1);

			var second:Object = s.rest().first();
			assertTrue("second should be a MapEntry of b and 1", second is MapEntry);
			assertTrue("second should be a MapEntry of b and 1", second.key == b);
			assertTrue("second should be a MapEntry of b and 1", second.value == 2);

			var third:Object = s.rest().rest().first();
			assertTrue("third should be a MapEntry of c and 1", third is MapEntry);
			assertTrue("third should be a MapEntry of c and 1", third.key == c);
			assertTrue("third should be a MapEntry of c and 1", third.value == 3);

			assertNull("should be at the end", s.rest().rest().rest());
		}


		public function testEach():void{
		 	var m:IMap = PersistentHashMap.createFromMany("one", 1, "two", 2, "three", 3);

		 	m.each(function(key:*, val:*):void{
		  			assertTrue("key should be a string", key is String);
		 		});

		 	var a:Object = {};
		 	var b:Object = {};
		 	var c:Object = {};
		 	m = PersistentHashMap.createFromMany(a, 1, b, 2, c, 3);
		 	m.each(function(key:*, val:*):void{
		  			assertTrue("key should be an object", key is Object);
		 		});
		}




		// 		public function testMapEquality():void{
		// 			assertTrue("maps should be equal", PersistentHashMap.createFromArray(["a", 1, "b", 2]).equals(PersistentHashMap.createFromArray(["a", 1, "b", 2])));
		// 			assertFalse("maps should NOT be equal", PersistentHashMap.createFromArray(["a", 1, "b", 3]).equals(PersistentHashMap.createFromArray(["a", 1, "b", 2])));
		// 			assertFalse("maps should NOT be equal", PersistentHashMap.createFromArray(["a", 0, "b", 2]).equals(PersistentHashMap.createFromArray(["a", 1, "b", 2])));
		// 			assertFalse("maps should NOT be equal", PersistentHashMap.createFromArray(["a", 1, "b", 2, "c", 4]).equals(PersistentHashMap.createFromArray(["a", 1, "b", 2])));
		// 			assertFalse("maps should NOT be equal", PersistentHashMap.createFromArray(["a", 1, "b", 2]).equals(PersistentHashMap.createFromArray(["a", 1, "b", 2, "c", 3, "d", 4])));
		// 		}

		// 		public function testMapSequencing():void{
		// 			var m:PersistentHashMap = PersistentHashMap.createFromArray(["a", 1, "b", 2, "c", 3, "d", 4]);
		// 			var s:ISeq = m.seq();
		// 			assertTrue("first is ['a', 1]", m.valAt(s.first().key) == s.first().value);
		// 		}

	}

}