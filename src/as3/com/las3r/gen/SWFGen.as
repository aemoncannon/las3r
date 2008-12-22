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
		private var _exprs:Array = [];
		private var _moduleId:String;
		private var _finalized:Boolean = false;
		private var _vars:IMap = RT.map();
		private var _keywords:IMap = RT.map();
		private var _constants:IMap = RT.map();
		private var _rt:RT;

		protected function emitStatics(gen:CodeGen, staticsGuid:String, rtTmpIndex:int):void{
            var basename = gen.emitter.qname({ns: "", id: "Object" }, false);
			var classname = gen.emitter.qname({ns: "", id: staticsGuid }, false);

			var cls = gen.scr.newClass(classname, basename);

            /* Static initializer, we can't init fields here, as we don't have an RT instance. */
            var cinit = cls.getCInit();
			var asm = cinit.asm;
			asm.I_returnvoid();
			

			/* Constructor, just a place holder. */
			var inst = cls.getInstance();
			var method = new Method(gen.emitter, [], false, false, 2, "$construct", false);
			asm = method.asm;
			asm.I_getlocal(0);
			asm.I_pushscope();
			asm.I_getlocal(0);
            asm.I_constructsuper(0);
            asm.I_returnvoid();
			inst.setIInit(method.finalize());

			/* For each constant, create a slot on the class */
			var i:int = 0;
            _constants.each(function(id:int, obj:Object):void{
					//var parts:Array = clazz.split(".");
					//var className:String = parts.pop();
					cls.addTrait(new ABCSlotTrait(
							gen.emitter.nameFromIdent(CodeGen.constantName(id)), /*field name*/
							0, /*attrs*/
							false, /*const?*/
							i + 1, /*slot_id 0 tells AVM to auto-assign*/
							0, /* any type */ //gen.emitter.qname({ns: "com.las3r.runtime", id: "RT" }, false), 
							0, /* static value lookup */
							0 /*kind, var*/
						));
					i++;
				});

			var clsidx:int = cls.finalize(); 

			/* Instantiate the class and store it in global*/
            gen.asm.I_findpropstrict(basename);
            gen.asm.I_getproperty(basename);
            gen.asm.I_dup();
            gen.asm.I_pushscope();
            gen.asm.I_newclass(clsidx);
            gen.asm.I_dup(); // We'll need this class object later..
            gen.asm.I_popscope();
            gen.asm.I_getglobalscope();
            gen.asm.I_swap();
            gen.asm.I_initproperty(classname);

			//Dup'ed class object should now be on TOS

			/* For each constant, populate a static field on our newly created class */
            Var.pushBindings(_rt, RT.map(_rt.PRINT_READABLY, RT.T));
			i = 0;
            _constants.each(function(id:int, obj:Object):void{
					var cs:String = null;
					try
					{
						cs = _rt.printString(obj);
					}
					catch (e:Error)
					{
						throw new Error("RuntimeException: Can't embed object in code, maybe print-dup not defined: " + obj);
					}
					if (cs.length == 0)
					throw new Error("RuntimeException: Can't embed unreadable object in code: " + obj);
					
					if (cs.match("^#<"))
					throw new Error("RuntimeException: Can't embed unreadable object in code: " + cs);

 					gen.asm.I_dup(); // Keep a copy of the class object on the stack..
					gen.asm.I_getlocal(rtTmpIndex);
 					gen.asm.I_pushstring(gen.emitter.constants.stringUtf8(cs));
					gen.asm.I_callproperty(gen.emitter.nameFromIdent("readString"), 1);
 					gen.asm.I_setslot(i + 1);
					i++;
				});
            Var.popBindings(_rt);

			gen.asm.I_pop(); // Get rid of the class object..
		}


		protected function emitModule():void{
			var staticsGuid:String = GUID.create();
			var gen:CodeGen = new CodeGen(staticsGuid, _emitter, _script, null, _vars, _keywords, _constants);

			gen.pushThisScope();
			gen.pushNewActivationScope();

			/* Define module constructor function.. */
			var formalsTypes:Array = [0, 0, 0]; //rt:*, callback:*, errorCallback*
			var methGen = gen.newMethodCodeGen(formalsTypes, false, false, gen.asm.currentScopeDepth, _moduleId);
			methGen.pushThisScope();
			methGen.pushNewActivationScope();

			var rtTmp:int = 1;
			var callbackTmp:int = 2;
			var errorCallbackTmp:int = 3;

			emitStatics(methGen, staticsGuid, rtTmp);

 	        methGen.asm.I_getlex(methGen.emitter.qname({ns: "", id: staticsGuid }, false));
			methGen.asm.I_getlocal(rtTmp);
			methGen.asm.I_setproperty(methGen.emitter.nameFromIdent("rt"));

			var tryStart:Object = methGen.asm.I_label(undefined);
			methGen.asm.I_getlocal(callbackTmp); // the result callback
			methGen.asm.I_pushnull(); // the receiver
			if(_exprs.length > 0){
				var expr:Expr;
				for(var i:int = 0; i < _exprs.length - 1; i++){
					expr = Expr(_exprs[i]);
					expr.emit(C.STATEMENT, methGen);
				}
				expr = Expr(_exprs[_exprs.length - 1]);
				expr.emit(C.EXPRESSION, methGen);
			}
			else{
				methGen.asm.I_pushnull();
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
			gen.provideModule(_moduleId);
		}

		public function addExpr(expr:Expr, vars:IMap, keywords:IMap, constants:IMap):void{
			if(_finalized) throw new Error("IllegalStateException: SWFGen already finalized.");

			for(var s:ISeq = vars.seq(); s != null; s = s.rest()){
				var e:MapEntry = MapEntry(s.first());
				_vars = _vars.cons(e);
			}
			for(s = keywords.seq(); s != null; s = s.rest()){
				e = MapEntry(s.first());
				_keywords = _keywords.cons(e);
			}
			for(s = constants.seq(); s != null; s = s.rest()){
				e = MapEntry(s.first());
				_constants = _constants.cons(e);
			}
			_exprs.push(expr);
		}

		public function emit():ByteArray{
			if(_finalized) throw new Error("IllegalStateException: SWFGen already finalized.");
			emitModule();
			var file:ABCFile = _emitter.finalize();
			var bytes:ByteArray = file.getBytes();
			bytes.position = 0;
			_finalized = true;
			return ByteLoader.wrapInSWF([bytes]);
		}


		public function SWFGen(rt:RT, moduleId:String){
			_rt = rt;
			_moduleId = moduleId;
			_emitter = new ABCEmitter();
			_script = _emitter.newScript();
		}

		
	}


}

