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
	import com.las3r.runtime.IVector;
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

		public function testSequencing():void{
			var l:PersistentVector = PersistentVector.createFromArray([1, 2, 3, 4]);
			var s:ISeq = l.seq();
			assertTrue("first is 1", s.first() == 1);
			assertTrue("first of rest is 2", s.rest().first() == 2);
		}


		public function testCons():void{
			var l:PersistentVector = PersistentVector.createFromMany(1, 2, 3, 4);
			l = PersistentVector(l.cons(5));
			l = PersistentVector(l.cons(6));
			assertTrue("l should have 5 and 6 appended to end", l.equals(PersistentVector.createFromMany(1, 2, 3, 4, 5, 6)));
		}

		public function testAssocN():void{
			var l:PersistentVector = PersistentVector.createFromMany(1, 2, 3, 4);
			l = PersistentVector(l.assocN(0, 10));
			assertTrue("l should now have 10 in 0 place", l.equals(PersistentVector.createFromMany(10, 2, 3, 4)));
			l = PersistentVector(l.assocN(0, 5));
			assertTrue("l should now have 5 in 0 place", l.equals(PersistentVector.createFromMany(5, 2, 3, 4)));
		}

		public function testNth():void{
			var l:PersistentVector = PersistentVector.createFromMany(1, 2, 3, 4);
			assertTrue("item in 0 place should be 1", l.nth(0) == 1);
		}

		public function testPeek():void{
			var l:PersistentVector = PersistentVector.createFromMany(1, 2, 3, 4);
			assertTrue("peeked item should be 4", l.peek() == 4);
			l = PersistentVector(l.pop());
			assertTrue("poped vector should be 1,2,3", l.equals(PersistentVector.createFromMany(1, 2, 3)));
		}

		public function testContainsKey():void{
			var l:PersistentVector = PersistentVector.createFromMany(1, 2, 3, 4);
			assertTrue("l should containsKey 3", l.containsKey(3));
			assertFalse("l should not containsKey 4", l.containsKey(4));
		}



	}

}