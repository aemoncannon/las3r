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
	import com.las3r.runtime.*;

	public class NamespaceTest extends RichTestCase {
		
		override public function setUp():void {
		}
		
		override public function tearDown():void {
		}

		public function testCreateAndFind():void{
			var rt:RT = new RT();
			var ns:LispNamespace = LispNamespace.findOrCreate(rt, Symbol.intern1(rt, "aemon"));
			assertNotNull("ns should not be null", ns);
			var ns2:LispNamespace = LispNamespace.find(rt, Symbol.intern1(rt, "aemon"));
			assertTrue("found should be == to created", ns == ns2);
		}

		public function testRemove():void{
			var rt:RT = new RT();
			var ns:LispNamespace = LispNamespace.findOrCreate(rt, Symbol.intern1(rt, "dog"));
			assertNotNull("ns should not be null", ns);
			LispNamespace.remove(rt, Symbol.intern1(rt, "dog"));
			assertNull("ns should not be null", LispNamespace.find(rt, Symbol.intern1(rt, "dog")));
		}

	}

}