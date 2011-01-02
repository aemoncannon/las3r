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
	import flash.events.*;
	import com.las3r.runtime.*;
	import com.las3r.util.*;

	public class RTTest extends LAS3RTest {
		
		override public function setUp():void {
		}
		
		override public function tearDown():void {
		}

		public function testConcat1():void{
			var rt:RT = new RT();
			var l:ISeq = RT.list(sym1(rt, "a"), sym1(rt, "b"), sym1(rt, "c"));
			assertTrue("val should be equivalent..", Util.equal(RT.list(sym1(rt, "a"), sym1(rt, "b"), sym1(rt, "c")), RT.concat(l)));
		}

		public function testConcat2():void{
			var rt:RT = new RT();
			var l1:ISeq = RT.list(sym1(rt, "a"), sym1(rt, "b"), sym1(rt, "c"));
			var l2:ISeq = RT.list(sym1(rt, "q"), sym1(rt, "r"), sym1(rt, "x"));
			assertTrue("val should be equivalent..", Util.equal(RT.list(sym1(rt, "a"), sym1(rt, "b"), sym1(rt, "c"), sym1(rt, "q"), sym1(rt, "r"), sym1(rt, "x")), RT.concat(l1, l2)));
		}

		public function testVectorNth():void{
			var notFound:Object = new Object;
			var v:PersistentVector = PersistentVector.createFromMany(0, 42);
			assertTrue("Value at index 0 should be 0", RT.nth(v, 0, notFound) === 0);
			assertTrue("Value at index 1 should be 42", RT.nth(v, 1, notFound) === 42);
		}

		public function testArrayNth():void{
			var notFound:Object = new Object;
			var a:Array = [0, 42];
			assertTrue("Value at index 0 should be 0", RT.nth(a, 0, notFound) === 0);
			assertTrue("Value at index 1 should be 42", RT.nth(a, 1, notFound) === 42);
			assertTrue("Value at (non-existent) index 2 should be notFound", RT.nth(a, 2, notFound) === notFound);
			assertTrue("Value at (non-existent) index 2 should be 0", RT.nth(a, 2, 0) === 0);
		}

		public function testAVMVector():void{
			var notFound:Object = new Object;
			var v:Vector.<int> = new Vector.<int>();
			v[0] = 0;
			v[1] = 1;
			v[2] = 2;
			assertTrue("Value at index 1 should be 1", RT.nth(v, 1, notFound) === 1);
			assertTrue("Value at index 1 should be 1", RT.get(v, 1, notFound) === 1);
			assertTrue("Count should be 3", RT.count(v) === 3);
			assertTrue("Vector should contain 1", RT.contains(v, 1));
			assertFalse("Vector not should contain 5", RT.contains(v, 5));
			assertTrue("Second object in seq should be 1", RT.second(RT.seq(v)) === 1);
		}
	}
}
