/**
* Copyright (c) Aemon Cannon. All rights reserved.
* The use and distribution terms for this software are covered by the
* Common Public License 1.0 (http://opensource.org/licenses/cpl.php)
* which can be found in the file CPL.TXT at the root of this distribution.
* By using this software in any fashion, you are agreeing to be bound by
* the terms of this license.
* You must not remove this notice, or any other, from this software.
*/


package com.cuttlefish.test{
	import flexunit.framework.TestCase;
 	import flexunit.framework.TestSuite;
	import flash.utils.*;
	import com.cuttlefish.runtime.List;

	public class ListTest extends RichTestCase {
		
		override public function setUp():void {
		}
		
		override public function tearDown():void {
		}

		public function testSimple():void{
			var l:List = List.createFromArray([1,2,3]);
			assertTrue("count should be 3", l.count() == 3);
			assertTrue("first element is 1", l.first() == 1);
			assertTrue("first of rest is 2", l.rest().first() == 2);
			assertTrue("first of rest of rest is 3", l.rest().rest().first() == 3);
			assertTrue("rest of rest of rest is null", l.rest().rest().rest() == null);
		}


		public function testListEquality():void{
			assertTrue("lists should be equal", List.createFromArray([1, 2, 3]).equals(List.createFromArray([1, 2, 3])));
			assertFalse("lists should NOT be equal", List.createFromArray([1, 2, 0]).equals(List.createFromArray([1, 2, 3])));
			assertFalse("lists should NOT be equal", List.createFromArray([0, 2, 3]).equals(List.createFromArray([1, 2, 3])));
			assertFalse("lists should NOT be equal", List.createFromArray([1, 2, 3, 4]).equals(List.createFromArray([1, 2, 3])));
			assertFalse("lists should NOT be equal", List.createFromArray([1, 2, 3]).equals(List.createFromArray([1, 2, 3, 4])));
		}

	}

}