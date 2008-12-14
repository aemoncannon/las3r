/**
*   Copyright (c) Rich Hickey. All rights reserved.
*   Copyright (c) Aemon Cannon. All rights reserved.
*   The use and distribution terms for this software are covered by the
*   Common Public License 1.0 (http://opensource.org/licenses/cpl.php)
*   which can be found in the file CPL.TXT at the root of this distribution.
*   By using this software in any fashion, you are agreeing to be bound by
* 	 the terms of this license.
*   You must not remove this notice, or any other, from this software.
**/

package com.las3r.gen{
	import flash.utils.*;
	import com.las3r.runtime.*;
	import com.las3r.util.*;
	import com.hurlant.eval.ByteLoader;
	import com.hurlant.eval.gen.Script;
	import com.hurlant.eval.gen.Method;
	import com.hurlant.eval.gen.ABCEmitter;
	import com.hurlant.eval.gen.AVM2Assembler;
	import com.hurlant.eval.abc.ABCFile;
	import com.hurlant.eval.abc.ABCSlotTrait;
	import com.hurlant.eval.abc.ABCException;
	import org.pranaframework.reflection.Type;
	import org.pranaframework.reflection.Field;


	public class SWFGen{
		private var _emitter:ABCEmitter;
		private var _script:Script;
		private var _initGen:CodeGen;
		private var _moduleId:String;

		public static function createModuleSwf(moduleId:String, exprs:Array):SWFGen{
			var swf:SWFGen = new SWFGen(moduleId, new Lock());
			swf.emitModule(moduleId, exprs);
			return swf;
		}


		protected function emitModule(moduleId:String, exprs:Array):void{

			var gen:CodeGen = _initGen;
			gen.pushThisScope();
			gen.pushNewActivationScope();

			/* Define module constructor function.. */

			var formalsTypes:Array = [0, 0, 0]; //rt:*, callback:*, errorCallback*
			var methGen = gen.newMethodCodeGen(formalsTypes, false, false, gen.asm.currentScopeDepth, moduleId);
			methGen.pushThisScope();
			methGen.pushNewActivationScope();

			var rtTmp:int = 1;
			var callbackTmp:int = 2;
			var errorCallbackTmp:int = 3;

			methGen.registerRTInstance(rtTmp);

			var tryStart:Object = methGen.asm.I_label(undefined);
			methGen.asm.I_getlocal(callbackTmp); // the result callback
			methGen.asm.I_pushnull(); // the receiver
			if(exprs.length > 0){
				for(var i:int = 0; i < exprs.length - 1; i++){
					var expr:Expr = Expr(exprs[i]);
					expr.emit(C.STATEMENT, methGen);
				}
				expr = Expr(exprs[exprs.length - 1]);
				expr.emit(C.EXPRESSION, methGen);
			}
			methGen.asm.I_call(1); // invoke result callback
 			var tryEnd:Object = methGen.asm.I_label(undefined);

 			var catchEnd:Object = methGen.asm.newLabel();
 			methGen.asm.I_jump(catchEnd);

 			var catchStart:Object = methGen.asm.I_label(undefined);
 			var excId:int = methGen.meth.addException(new ABCException(
 					tryStart.address, 
 					tryEnd.address, 
 					catchStart.address,
 					0, // *
 					methGen.emitter.nameFromIdent("toplevelExceptionHandler")
 				));
 			methGen.asm.startCatch(); // Increment max stack by 1, for exception object
 			methGen.restoreScopeStack(); // Scope stack is wiped on exception, so we reinstate it..
 			methGen.pushCatchScope(excId);

			methGen.asm.I_getlocal(errorCallbackTmp); // the error callback
			methGen.asm.I_swap(); 
			methGen.asm.I_pushnull(); // the receiver
			methGen.asm.I_swap(); 
			methGen.asm.I_call(1); // invoke error callback

			methGen.popScope(); 
			methGen.asm.I_returnvoid();
 			methGen.asm.I_label(catchEnd);
			methGen.asm.I_returnvoid();

			/* Module constructor finished. Now, provide the module.. */

			gen.asm.I_newfunction(methGen.meth.finalize());
			gen.provideModule(moduleId);
		}

		public function getSWFBytes():ByteArray{
			var file:ABCFile = _emitter.finalize();
			var bytes:ByteArray = file.getBytes();
			bytes.position = 0;
			return ByteLoader.wrapInSWF([bytes]);
		}

		public function SWFGen(moduleId:String, l:Lock){
			_moduleId = moduleId;
			_emitter = new ABCEmitter();
			_script = _emitter.newScript();

			var rtGuid:String = GUID.create();
			_initGen = new CodeGen(rtGuid, _emitter, _script);
		}
		
	}


}

class Lock{}