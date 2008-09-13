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
 	import flash.events.*;
 	import flash.external.*;
 	import flash.utils.*;
	import com.las3r.runtime.*;
	import com.las3r.util.Util;
	import com.las3r.io.StringReader;
	import com.las3r.io.PushbackReader;

	public class LAS3RTest extends RichTestCase  {

		protected var illegalStateP:Function = function(e:Error):Boolean{ return e.message.match("IllegalStateException"); };

		protected function readStr(rt:RT, str:String):Object{
			return (new LispReader(rt)).read(new PushbackReader(new StringReader(str)));
		}

		protected function key1(rt:RT, name:String):Keyword{
			return Keyword.intern1(rt, sym1(rt, name));
		}

		protected function sym1(rt:RT, name:String):Symbol{
			return Symbol.intern1(rt, name);
		}

		protected function sym2(rt:RT, ns:String, name:String):Symbol{
			return Symbol.intern2(rt, ns, name);
		}

		protected function readAndLoad(str:String, callback:Function, runtime:RT = null):void{
			var rt:RT;
			if(runtime){
				rt = runtime;
			}
			else{
				rt = new RT();
				rt.init();
			}
			var c:Compiler = new Compiler(rt);
			c.compileAndLoad(readStr(rt, str), willCall(function(e:Event):void{ callback(rt); }, 1000));
		}

	}
}

