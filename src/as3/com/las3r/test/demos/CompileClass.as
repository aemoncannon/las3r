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
	import com.hurlant.eval.gen.Method;
	import com.hurlant.eval.gen.ABCEmitter;
	import com.hurlant.eval.gen.AVM2Assembler;
	import com.hurlant.eval.abc.*;
	import com.hurlant.eval.ByteLoader;
	import com.hurlant.eval.dump.ABCDump;

	public class CompileClass extends Sprite{

		public function CompileClass():void{
			var e = new ABCEmitter;
			var s = e.newScript();
			var context:CompilationContext = new CompilationContext(e, s);

			var asm:AVM2Assembler = s.init.asm;
			var baseName:String = "Object"
			var className:String = "dkfjonkeyslkdjf22wjlkwqlkjsd"
			var clsidx:int = compileClass(context, baseName, className);

			var classname = e.qname({ns: "", id: className }, false);
            var basename = e.qname({ns: "", id: baseName }, false);

            asm.I_getlocal(0);
            asm.I_pushscope();
            asm.I_findpropstrict(basename);
            asm.I_getproperty(basename);
            asm.I_dup();
            asm.I_pushscope();
            asm.I_newclass(clsidx);
            asm.I_popscope();
            asm.I_getglobalscope();
            asm.I_swap();
            asm.I_initproperty(classname);

 	        asm.I_getlex(classname);
// 			asm.I_coerce(e.qname({ns: "", id: "Class" }, false))
// 			asm.I_getslot(1);
			asm.I_getproperty(e.nameFromIdent("rt"));
 			asm.I_throw();

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
		public static function compileClass(ctx:CompilationContext, baseName:String, className:String) {
			var emitter:ABCEmitter = ctx.emitter, script:Script = ctx.script;

			var classname = emitter.qname({ns: "", id: className }, false);
            var basename = emitter.qname({ns: "", id: baseName }, false);

			var cls = script.newClass(classname, basename);

			cls.addTrait(new ABCSlotTrait(
					emitter.nameFromIdent("rt"), /*field name*/
					0, /*attrs*/
					false, /*const?*/
					1, /*slot_id 0 tells AVM to auto-assign*/
					emitter.qname({ns: "", id: "String" }, false), 
					0, /* static value lookup */
					0 /*kind, var*/
				));

            // cinit - init static fixtures
            var cinit = cls.getCInit();
			var asm = cinit.asm;
			asm.I_getlocal(0);
			asm.I_pushstring(emitter.constants.stringUtf8("hello"));
			asm.I_setslot(1);
			asm.I_returnvoid();
			
			var inst = cls.getInstance();
			var method = new Method(emitter, [], false, false, 2, "$construct", false);
			asm = method.asm;

			asm.I_getlocal(0);
			asm.I_pushscope();

			asm.I_getlocal(0);
            asm.I_constructsuper(0);
            asm.I_returnvoid();

			inst.setIInit(method.finalize());


            var clsidx = cls.finalize();
			return clsidx;
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