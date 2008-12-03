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
	import flash.events.*;
	import com.cuttlefish.runtime.*;
	import com.cuttlefish.util.*;

	public class RTTest extends CUTTLEFISHTest {
		
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

	}
}
