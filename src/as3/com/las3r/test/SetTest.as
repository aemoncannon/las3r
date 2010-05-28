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
	import com.las3r.runtime.PersistentHashSet;
	import com.las3r.runtime.ISet;
	import com.las3r.runtime.ISeq;

	public class SetTest extends LAS3RTest {
		
		override public function setUp():void {
		}
		
		override public function tearDown():void {
		}

		public function testSimple():void{
			var s:ISet = PersistentHashSet.createFromMany(1, 2, 3);
 			assertTrue("set should contain 1", s.contains(1));
 			assertTrue("set should contain 2", s.contains(2));
 			assertTrue("set should contain 3", s.contains(3));
 			assertFalse("set should not contain 4", s.contains(4));
 			assertTrue("count of set should be 3", s.count() == 3);
 			s = s.add(5);
 			assertTrue("set should contain 5", s.contains(5));
			s = s.remove(1);
 			assertFalse("set should not contain 1", s.contains(1));
 			assertTrue("count of set should be 3", s.count() == 3);
		}

		public function testDuplicatesHandling():void{
			var s:ISet = PersistentHashSet.createFromMany(1, 2, 3, 3, 2, 2, 2, 1, 1);
 			assertTrue("set should contain 1", s.contains(1));
 			assertTrue("set should contain 2", s.contains(2));
 			assertTrue("set should contain 3", s.contains(3));
 			assertTrue("count of set should be 3", s.count() == 3);
		}

		public function testAddRemove():void{
			var s:ISet = PersistentHashSet.createFromMany(1, 2);
 			assertTrue("set should contain 1", s.contains(1));
 			assertTrue("set should contain 2", s.contains(2));
 			assertTrue("count of set should be 2", s.count() == 2);

			s = s.add(1);
 			assertTrue("set should contain 1", s.contains(1));
 			assertTrue("set should contain 2", s.contains(2));
 			assertTrue("count of set should be 2", s.count() == 2);

			s = s.add(3);
 			assertTrue("set should contain 1", s.contains(1));
 			assertTrue("set should contain 2", s.contains(2));
 			assertTrue("set should contain 3", s.contains(3));
 			assertTrue("count of set should be 3", s.count() == 3);

			s = s.remove(3);
 			assertTrue("set should contain 1", s.contains(1));
 			assertTrue("set should contain 2", s.contains(2));
 			assertTrue("count of set should be 2", s.count() == 2);
		}
	}
}