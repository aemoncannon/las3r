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

	import com.las3r.runtime.*;
	import com.las3r.util.*;
	import com.hurlant.eval.gen.Script;
	import com.hurlant.eval.gen.Method;
	import com.hurlant.eval.gen.ABCEmitter;
	import com.hurlant.eval.gen.AVM2Assembler;
	import com.hurlant.eval.abc.ABCSlotTrait;
	import com.hurlant.eval.abc.ABCException;
	import org.pranaframework.reflection.Type;
	import org.pranaframework.reflection.Field;


	public class CodeGen{
		public var emitter:ABCEmitter;
		public var asm:AVM2Assembler;
		public var scr:Script;
		public var meth:Method;
		public var currentActivation:Object;
		public var cachedRTTempIndex:int = -1;
		public var scopeToLocalMap:IVector;
		protected var _rtInstanceId:String;

		public function CodeGen(rtInstanceId:String, emitter:ABCEmitter, scr:Script, meth:Method = null){
			_rtInstanceId = rtInstanceId;
			this.emitter = emitter;
			this.scr = scr;
			this.asm = meth ? meth.asm : scr.init.asm;
			this.meth = meth ? meth : scr.init;
			this.scopeToLocalMap = RT.vector();
		}



		public function newMethodCodeGen(formals:Array, needRest:Boolean, needArguments:Boolean, scopeDepth:int, name:String):CodeGen{
			return new CodeGen(_rtInstanceId, this.emitter, this.scr, this.scr.newFunction(formals, needRest, needArguments, scopeDepth, name));
		}



		public function nextActivationSlot():int{
			if(!currentActivation){ throw new Error("IllegalStateException: No activation is current."); }
			var i:int = currentActivation.nextSlot;
			currentActivation.nextSlot += 1;
			return i;
		}

		public function createActivationSlotForLocalBinding(b:Object/*LocalBinding*/):int{
			var activationSlot:int = nextActivationSlot();
			b.slotIndex = activationSlot;
			meth.addTrait(new ABCSlotTrait(emitter.nameFromIdent(b.runtimeName), 0, false, activationSlot, 0, 0, 0));
			return activationSlot;
		}

		/*
		* Create a new function activation, push it onto the scope stack, and keep track of it for later,
		* for when we need to store or get local vars into the current activation.
		*
		* Stack:   
		*   ... => ...
		*/
		public function pushNewActivationScope():void{
			asm.I_newactivation();
			asm.I_dup();
			asm.I_pushscope();
			currentActivation = { scopeIndex: asm.currentLocalScopeDepth - 1, nextSlot: 1 };
			var i:int = asm.getTemp();
			asm.I_setlocal(i);
			scopeToLocalMap = scopeToLocalMap.cons(i);
		}


		/*
		* For the current method, push 'this' onto the scope stack. 'this' is initially found
		* at register 0, so we just leave it there and remember the location in scopeToLocalMap.
		*
		* Stack:   
		*   ... => ...
		*/
		public function pushThisScope():void{
			asm.I_getlocal_0();
			asm.I_pushscope();
			asm.useTemp(0)
			scopeToLocalMap = scopeToLocalMap.cons(0);
		}


		/*
		* Replace current activation object with a fresh one.
		*
		* NOTE! This assumes current activation is on top of scope stack.
		*
		* Stack:   
		*   ... => ...
		*/
		public function refreshCurrentActivationScope():void{
			if(currentActivation.scopeIndex != (asm.currentLocalScopeDepth - 1)){
				throw new Error("IllegalStateException: 'refreshCurrentActivationScope' expects current activation to be on top of scope stack.");
			}
			asm.I_popscope();
			asm.I_newactivation();
			asm.I_dup();
			asm.I_pushscope();
			var i:int = int(this.scopeToLocalMap.nth(this.scopeToLocalMap.count() - 1));
			asm.I_setlocal(i);
		}


		/*
		* Used when restoring scope stack in exception handler. Takes scope object stored in local registers
		* and adds them back onto the scope stack.
		*
		* Stack:   
		*   ... => ...
		*/
		public function restoreScopeStack():void{
			var len:int = this.scopeToLocalMap.count();
			for(var i:int = 0; i < len; i++){
				asm.I_getlocal(i);
				asm.I_pushscope();				
			}
		}


		/*
		* Push a new catch clause scope onto the scope stack.
		*
		* Stack:   
		*   thrown, catchTypeName => thrown
		*/
		public function pushCatchScope(i:int):void{
			asm.I_newcatch(i);
			asm.I_dup();
			asm.I_pushscope();
			var i:int = asm.getTemp()
			asm.I_setlocal(i);
			scopeToLocalMap = scopeToLocalMap.cons(i);
		}

		/*
		* Pop the scope stack.
		*
		* Stack:   
		*   ... => ...
		*/
		public function popScope():void{
			asm.I_popscope();
			asm.freeTemp(scopeToLocalMap.peek());
			scopeToLocalMap = scopeToLocalMap.pop();
		}


		/*
		* Stack:   
		*   ... => anRTClass
		*/
		public function getRTClass():void{
			asm.I_getlex(emitter.qname({ns: "com.las3r.runtime", id:"RT"}, false));
		}



		/*
		* Get the active instance of RT.
		*
		* Stack:   
		*   ... => anRT
		*/
		protected function getRT():void{
			if(cachedRTTempIndex > -1){
				asm.I_getlocal(cachedRTTempIndex);
			}
			else{
				getRTClass();
				asm.I_getproperty(emitter.nameFromIdent("instances"));
				asm.I_getproperty(emitter.nameFromIdent(_rtInstanceId));
			}
		}


		/*
		* Store the active instance of RT in a temp
		*
		* Stack:   
		*   ... => ...
		*/
		public function cacheRTInstance():void{
			getRTClass();
			asm.I_getproperty(emitter.nameFromIdent("instances"));
			asm.I_getproperty(emitter.nameFromIdent(_rtInstanceId));
			var i:int = asm.getTemp();
			asm.I_setlocal(i);
			cachedRTTempIndex = i;
		}




		/*
		* Stack:   
		*   ... => const
		*/
		public function getConstant(id:int, name:String, type:Class):void{
			getRT();
 			asm.I_getproperty(emitter.nameFromIdent("constants"));
			asm.I_pushint(emitter.constants.int32(id + 1));
			asm.I_nextvalue();
		}


		/*
		* A debug helper... not meant for long-term usage.
		* Stack:   
		*   val => ...
		*/
		public function print():void{
			getRTClass();
			asm.I_swap();
			asm.I_callproperty(emitter.nameFromIdent("printToString"), 1);
			getRT();
			asm.I_swap();
			asm.I_callpropvoid(emitter.nameFromIdent("writeToStdout"), 1);
		}


		/*
		* Store the value at TOS at key in RT.
		* Stack:   
		*   val => ...
		*/
		public function callbackWithResult(key:String):void{
			getRT();
			asm.I_swap();
			asm.I_pushstring( emitter.constants.stringUtf8(key));
			asm.I_callpropvoid(emitter.nameFromIdent("callbackWithResult"), 2);
		}


		/*
		* Stack:   
		*   aVar,init => ...
		*/
		public function bindVarRoot():void{
			asm.I_callpropvoid(emitter.nameFromIdent("bindRoot"), 1);
		}


		/*
		* Stack:   
		*   aVar,meta => ...
		*/
		public function setMeta():void{
			asm.I_callpropvoid(emitter.nameFromIdent("setMeta"), 1);
		}


		/*
		* Stack:   
		*   aVar => val
		*/
		public function getVar():void{
			asm.I_callproperty(emitter.nameFromIdent("get"), 0);
		}


		/*
		* Stack:   
		*   anArray => aVector
		*/
		public function arrayToVector():void{
			asm.I_getlex(emitter.qname({ns: "com.las3r.runtime", id:"Vector"}, false))
			asm.I_swap();
			asm.I_construct(1);
		}

		/*
		* Stack:   
		*   anArray => aList
		*/
		public function restFromArguments(i:int):void{
			getRTClass();
			asm.I_swap();
			asm.I_pushint(emitter.constants.int32(i));
			asm.I_callproperty(emitter.nameFromIdent("restFromArguments"), 2);
		}


		/*
		* Stack:   
		*   anRTClass, val0, val1, val2, valn => aVector
		*/
		public function newVector(n:int):void{
			asm.I_callproperty(emitter.nameFromIdent("vector"), n);
		}

		/*
		* Stack:   
		*   anRTClass, key0, val0, key1, val1, keyn, valn => aMap
		*/
		public function newMap(n:int):void{
			asm.I_callproperty(emitter.nameFromIdent("map"), n);
		}


		/*
		* Stack:   
		*   aVar,val => val
		*/
		public function setVar():void{
			asm.I_callproperty(emitter.nameFromIdent("set"), 1);
		}

	}
}