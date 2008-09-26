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

	public class LibTest extends LAS3RTest {
		
		override public function setUp():void {
		}
		
		override public function tearDown():void {
		}

		public function testMacroexpandIsDefined():void{
			var rt:RT = new RT();
			rt.loadStdLib(willCall(function(val:*):void{
						var v:Var = rt.getVar("las3r", "macroexpand");
						assertTrue("macroexpand should be defined", v.get() is Function);
					}, 5000));
		}

		public function testNotIsDefined():void{
			var rt:RT = new RT();
			rt.loadStdLib(willCall(function(val:*):void{
						var v:Var = rt.getVar("las3r", "not");
						assertTrue("'not' should be defined", v.get() is Function);
					}, 5000));
		}

		public function testNotFunction():void{
			var rt:RT = new RT();
			rt.loadStdLib(function(val:*):void{
					readAndLoad("(not true)",function(rt:RT, val:*):void{
							assertTrue("val should be false", val == false);
						}, 
						rt
					);
				});
		}


	}
}
