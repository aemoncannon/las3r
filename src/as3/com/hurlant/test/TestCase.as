/**
 * TestCase
 * 
 * Embryonic unit test support class.
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.test
{
	public class TestCase 
	{
		public var harness:ITestHarness;
		private var failed:Boolean;
		
		public function TestCase(h:ITestHarness, title:String) {
			harness = h;
			harness.beginTestCase(title);
		}
		
		
		public function assert(msg:String, value:Boolean):void {
			if (value) {
//				TestHarness.print("+ ",msg);
				return;
			}
			throw new Error("Test Failure:"+msg);
		}
		
		public function claim(msg:String, value:Boolean):void {
			if(value) return;
			failed = true;
			harness.failTest("Test Failure:"+msg)
		}
		
		public function runTest(f:Function, title:String):void {
			failed=false;
			harness.beginTest(title);
			try {
				f();
			} catch (e:Error) {
				trace("EXCEPTION THROWN: "+e);
				trace(e.getStackTrace());
				harness.failTest(e.toString());
				return;
			}
			if (!failed) {
				harness.passTest();
			}
		}
	}
}