/**
* Copyright (c) Rich Hickey. All rights reserved.
* The use and distribution terms for this software are covered by the
* Common Public License 1.0 (http://opensource.org/licenses/cpl.php)
* which can be found in the file CPL.TXT at the root of this distribution.
* By using this software in any fashion, you are agreeing to be bound by
* the terms of this license.
* You must not remove this notice, or any other, from this software.
*/


package com.las3r.test.demos{
	import flash.display.*;
	import flash.events.*;
	import flash.external.*;
	import flash.utils.*;
	import com.hurlant.eval.gen.Script;
	import com.hurlant.eval.gen.ABCEmitter;
	import com.hurlant.eval.gen.AVM2Assembler;
	import com.hurlant.eval.abc.*;
	import com.hurlant.eval.ByteLoader;
	import com.hurlant.eval.dump.ABCDump;

	public class CompileSimpleFunction extends Sprite{

		public function CompileSimpleFunction():void{
			var e = new ABCEmitter;
			var s = e.newScript();
			var context:CompilationContext = new CompilationContext(e, s);

			var asm:AVM2Assembler = s.init.asm;
			var methId:int = compileFunc(context);
			var stringId:int = e.constants.stringUtf8("hello world!");
	        asm.I_newfunction(methId);
			asm.I_pushnull();
			asm.I_pushstring(stringId);
			asm.I_call(1);

			var file:ABCFile = e.finalize();
			var bytes:ByteArray = file.getBytes();
			bytes.position = 0;
			var swfBytes:ByteArray = ByteLoader.wrapInSWF([bytes]);
			trace(ABCDump.dump(swfBytes));
			bytes.position = 0;
			ByteLoader.loadBytes(bytes);
		}

		/* Create a method trait in the ABCFile
		* Generate code for the function
		* Return the function index
		*/
		static function compileFunc(ctx:CompilationContext) {
			var emitter:ABCEmitter = ctx.emitter, script:Script = ctx.script;
			var formals_type = [emitter.nameFromIdent("String")];
			var method = script.newFunction(formals_type, false, false, 0, "kdfj");
			var asm = method.asm;
			
			
			var t = asm.getTemp();
			asm.I_newactivation();
			asm.I_dup();
			asm.I_setlocal(t);
			asm.I_pushscope();

			/* Generate code for the body.  If there is no return statement in the
			* code then the default behavior of the emitter is to add a returnvoid
			* at the end, so there's nothing to worry about here.
			*/
			asm.I_findproperty(emitter.nameFromIdent("trace"));
			// get param
	        asm.I_getlocal(1);  //account for 'this'
			var stringId:int = emitter.constants.stringUtf8("hello");
			asm.I_pushstring(stringId);
			asm.I_throw();

			asm.I_kill(t);
			return method.finalize();
		}
		

	}

}

import com.hurlant.eval.gen.Script;
import com.hurlant.eval.gen.ABCEmitter;
class CompilationContext{
	public function CompilationContext(e:ABCEmitter, s:Script){
		this.emitter = e;
		this.script = s;
	}
	public var emitter:ABCEmitter;
	public var script:Script;
}