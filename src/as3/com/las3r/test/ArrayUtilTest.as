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
	import com.las3r.jdk.util.ArrayUtil;

	public class ArrayUtilTest extends RichTestCase {
		
		override public function setUp():void {
		}
		
		override public function tearDown():void {
		}

		public function testArrayCopy():void{
			var a:Array = [1,2,3,4];
			var b:Array = [1,2,3,4,5,6];
			ArrayUtil.arraycopy(a, 0, b, 4, 2);
			assertTrue("length should be the same", b.length == 6);
			assertTrue("should have correct elements", b[4] == 1);
			assertTrue("should have correct elements", b[5] == 2);
		}

	}

}