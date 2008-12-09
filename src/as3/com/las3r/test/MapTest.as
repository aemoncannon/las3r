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
	import com.las3r.runtime.RT;
	import com.las3r.runtime.IMap;
	import com.las3r.runtime.PersistentHashMap;
	import com.las3r.runtime.IMap;
	import com.las3r.runtime.ISeq;

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