/**
* Copyright (c) Rich Hickey. All rights reserved.
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

	public class VarTest extends LAS3RTest {
		
		override public function setUp():void {
		}
		
		override public function tearDown():void {
		}

		public function testGettingRoot():void{
			var rt:RT = new RT();
			var ns:LispNamespace = LispNamespace.findOrCreate(rt, Symbol.intern1(rt, "aemon"));
			var dude:Var = Var.internWithRoot(ns, Symbol.intern1(rt, "*dude*"), 25);
			assertTrue("dude.get should return the stored value", dude.get() == 25);
		}

		public function testGettingWithoutRootOrBinding():void{
			var rt:RT = new RT();
			var ns:LispNamespace = LispNamespace.findOrCreate(rt, Symbol.intern1(rt, "aemon"));
			var horse:Var = Var.internNS(ns, Symbol.intern1(rt, "*horse*"));
			assertThrows("should throw exception, can't get val with no binding or root", function():void{
					horse.get();
				}, illegalStateP);
		}

		public function testTryingToSetRoot():void{
			var rt:RT = new RT();
			var ns:LispNamespace = LispNamespace.findOrCreate(rt, Symbol.intern1(rt, "aemon"));
			var fish:Var = Var.internNS(ns, Symbol.intern1(rt, "*fish*"));
			assertThrows("should throw exception, can't set root val of var", function():void{
					fish.set(50);
				}, illegalStateP);
		}

		public function testPushingABinding():void{
			var rt:RT = new RT();
			var ns:LispNamespace = LispNamespace.findOrCreate(rt, Symbol.intern1(rt, "jugs"));
			var dude:Var = Var.internWithRoot(ns, Symbol.intern1(rt, "*dude*"), 25);
			assertTrue("dude.get should return root, 25", dude.get() == 25);
			Var.pushBindings(rt, RT.map(dude, 50));
			assertTrue("dude.get should return shadowed value, 50", dude.get() == 50);
			Var.popBindings(rt);
			assertTrue("dude.get should return root, 25", dude.get() == 25);
		}

		public function testPushingMultipleBindings():void{
			var rt:RT = new RT();
			var ns:LispNamespace = LispNamespace.findOrCreate(rt, Symbol.intern1(rt, "hello"));
			var dude:Var = Var.internWithRoot(ns, Symbol.intern1(rt, "*dude*"), 25);
			var cat:Var = Var.internWithRoot(ns, Symbol.intern1(rt, "*cat*"), "jugs");
			var horse:Var = Var.internWithRoot(ns, Symbol.intern1(rt, "*horse*"), 10);
			assertTrue("dude.get should return root, 25", dude.get() == 25);
			assertTrue("cat.get should return root, 'jugs'", cat.get() == "jugs");
			Var.pushBindings(rt, RT.map(dude, 50, cat, 100));
			assertTrue("dude.get should return shadowed value, 50", dude.get() == 50);
			assertTrue("cat.get should return shadowed value, 100", cat.get() == 100);
			Var.pushBindings(rt, RT.map(dude, 1, cat, 1, horse, 1));
			assertTrue("dude.get should return shadowed value, 1", dude.get() == 1);
			assertTrue("cat.get should return shadowed value, 1", cat.get() == 1);
			assertTrue("horse.get should return shadowed value, 1", horse.get() == 1);
			Var.popBindings(rt);
			Var.popBindings(rt);
			assertTrue("dude.get should return root, 25", dude.get() == 25);
			assertTrue("cat.get should return root, 'jugs'", cat.get() == "jugs");
			assertTrue("horse.get should return root, 1", horse.get() == 10);
		}

		public function testUsingSetToChangeBinding():void{
			var rt:RT = new RT();
			var ns:LispNamespace = LispNamespace.findOrCreate(rt, Symbol.intern1(rt, "cows"));
			var fish:Var = Var.internNS(ns, Symbol.intern1(rt, "*fish*"));
			Var.pushBindings(rt, RT.map(fish, 50));
			fish.set(100);
			assertTrue("fish.get should return new binding, 100", fish.get() == 100);
			Var.popBindings(rt);
			assertThrows("should throw exception, can't get val with no binding or root", function():void{
					fish.get();
				}, illegalStateP);
		}


	}

}