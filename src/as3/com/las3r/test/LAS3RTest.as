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
 	import flash.events.*;
 	import flash.external.*;
 	import flash.utils.*;
	import com.las3r.runtime.*;
	import com.las3r.util.Util;
	import com.las3r.jdk.io.StringReader;
	import com.las3r.jdk.io.PushbackReader;

	public class LAS3RTest extends RichTestCase  {

		protected var illegalStateP:Function = function(e:Error):Boolean{ return e.message.match("IllegalStateException"); };

		protected function readStr(rt:RT, str:String):Object{
			return rt.lispReader.read(new PushbackReader(new StringReader(str)));
		}

		protected function key1(rt:RT, name:String):Keyword{
			return rt.key1(sym1(rt, name));
		}

		protected function sym1(rt:RT, name:String):Symbol{
			return rt.sym1(name);
		}

		protected function sym2(rt:RT, ns:String, name:String):Symbol{
			return rt.sym2(ns, name);
		}

		protected function readAndLoad(str:String, callback:Function, runtime:RT = null, wait:Boolean = true):void{
			var rt:RT;
			if(runtime){
				rt = runtime;
			}
			else{
				rt = new RT();
			}
			if(wait){
				rt.evalStr(str, willCall(function(val:*):void{ callback(rt, val); }, 5000));
			}
			else{
				rt.evalStr(str, function(val:*):void{ callback(rt, val); });
			}
		}


	}
}

