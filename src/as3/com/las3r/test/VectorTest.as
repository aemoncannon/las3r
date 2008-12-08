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
	import com.las3r.runtime.PersistentVector;
	import com.las3r.runtime.ISeq;

	public class VectorTest extends RichTestCase {
		
		override public function setUp():void {
		}
		
		override public function tearDown():void {
		}

		public function testSimple():void{
			var v:PersistentVector = PersistentVector.createFromMany(1, 2, 3);
			assertTrue("count should be 3", v.count() == 3);
			assertTrue("first element is 1", v.nth(0) == 1);
			assertTrue("second element is 2", v.nth(1) == 2);
			assertTrue("third element is 3", v.nth(2) == 3);
			assertTrue("Should equal equivalent vector", v.equals(PersistentVector.createFromMany(1, 2, 3)))
		}

		public function testPersistentVectorEquality():void{
			assertTrue("vectors should be equal", PersistentVector.createFromArray([1, 2, 3]).equals(PersistentVector.createFromArray([1, 2, 3])));
			assertFalse("vectors should NOT be equal", PersistentVector.createFromArray([1, 2, 0]).equals(PersistentVector.createFromArray([1, 2, 3])));
			assertFalse("vectors should NOT be equal", PersistentVector.createFromArray([0, 2, 3]).equals(PersistentVector.createFromArray([1, 2, 3])));
			assertFalse("vectors should NOT be equal", PersistentVector.createFromArray([1, 2, 3, 4]).equals(PersistentVector.createFromArray([1, 2, 3])));
			assertFalse("vectors should NOT be equal", PersistentVector.createFromArray([1, 2, 3]).equals(PersistentVector.createFromArray([1, 2, 3, 4])));
		}

		public function testPersistentVectorSequencing():void{
			var l:PersistentVector = PersistentVector.createFromArray([1, 2, 3, 4]);
			var s:ISeq = l.seq();
			assertTrue("first is 1", s.first() == 1);
			assertTrue("first of rest is 2", s.rest().first() == 2);
		}

	}

}