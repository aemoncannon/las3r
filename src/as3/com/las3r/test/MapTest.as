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
	import com.las3r.runtime.Map;
	import com.las3r.runtime.IMap;
	import com.las3r.runtime.ISeq;

	public class MapTest extends RichTestCase {
		
		override public function setUp():void {
		}
		
		override public function tearDown():void {
		}

		public function testSimple():void{
			var m:IMap = Map.createFromMany("one", 1, "two", 2, "three", 3);
			assertTrue("'one' should be 1", m.valAt("one") == 1);
			assertTrue("count of map should be 3", m.count() == 3);
			m = m.assoc("dude", 5);
			assertTrue("'dude' should be 5", m.valAt("dude") == 5);
			assertTrue("'dudette' should be default val", m.valAt("dudette", "horse") == "horse");
		}

		public function testMapEquality():void{
			assertTrue("maps should be equal", Map.createFromArray(["a", 1, "b", 2]).equals(Map.createFromArray(["a", 1, "b", 2])));
			assertFalse("maps should NOT be equal", Map.createFromArray(["a", 1, "b", 3]).equals(Map.createFromArray(["a", 1, "b", 2])));
			assertFalse("maps should NOT be equal", Map.createFromArray(["a", 0, "b", 2]).equals(Map.createFromArray(["a", 1, "b", 2])));
			assertFalse("maps should NOT be equal", Map.createFromArray(["a", 1, "b", 2, "c", 4]).equals(Map.createFromArray(["a", 1, "b", 2])));
			assertFalse("maps should NOT be equal", Map.createFromArray(["a", 1, "b", 2]).equals(Map.createFromArray(["a", 1, "b", 2, "c", 3, "d", 4])));
		}

		public function testMapSequencing():void{
			var m:Map = Map.createFromArray(["a", 1, "b", 2, "c", 3, "d", 4]);
			var s:ISeq = m.seq();
			assertTrue("first is ['a', 1]", m.valAt(s.first().key) == s.first().value);
		}

	}

}