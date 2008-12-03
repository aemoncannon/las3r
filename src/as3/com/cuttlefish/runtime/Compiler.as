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

package com.cuttlefish.runtime{
	import com.cuttlefish.util.*;
	import com.cuttlefish.jdk.io.PushbackReader;
	import com.cuttlefish.errors.LispError;
	import com.cuttlefish.errors.CompilerError;
	import flash.utils.getQualifiedClassName;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.events.*;
	import com.hurlant.eval.gen.Script;
	import com.hurlant.eval.gen.ABCEmitter;
	import com.hurlant.eval.gen.AVM2Assembler;
	import com.hurlant.eval.abc.*;
	import com.hurlant.eval.ByteLoader;
	import com.hurlant.eval.dump.ABCDump;

	public class Compiler{

		public static var CONST_PREFIX:String = "const__";
		public static var MAX_POSITIONAL_ARITY:int = 8;

		private var _rt:RT;
		public var specialParsers:IMap;

		public var LINE:Var;
		public var SOURCE:Var;
		public var BINDING_SET_STACK:Var;
		public var RECURING_BINDER:Var;
		public var RECUR_ARGS:Var;
		public var RECUR_LABEL:Var;
		public var IN_CATCH_FINALLY:Var;

		public function get rt():RT{ return _rt; }
		public function get constants():Array{ return _rt.constants; }
		public function get keywords():Dictionary{ return _rt.keywords; }
		public function get vars():Dictionary{ return _rt.vars; }

		public function Compiler(rt:RT){
			_rt = rt;

			specialParsers = RT.map(
				_rt.DEF, DefExpr.parse,
				_rt.RECUR, RecurExpr.parse,
				_rt.IF, IfExpr.parse,
				_rt.LET, LetExpr.parse,
				_rt.DO, BodyExpr.parse,
				_rt.QUOTE, ConstantExpr.parse,
				_rt.THE_VAR, TheVarExpr.parse,
				_rt.DOT, HostExpr.parse,
				_rt.ASSIGN, AssignExpr.parse,
				_rt.TRY, TryExpr.parse,
				_rt.THROW, ThrowExpr.parse,
				_rt.NEW, NewExpr.parse
			);

			SOURCE = new Var(_rt, null, null, "Evaluated Source");
			LINE = new Var(_rt, null, null, 0);
			BINDING_SET_STACK = new Var(_rt, null, null, RT.vector());
			RECURING_BINDER = new Var(_rt, null, null, null);
			RECUR_ARGS = new Var(_rt, null, null, null);
			RECUR_LABEL = new Var(_rt, null, null, null);
			IN_CATCH_FINALLY = new Var(_rt, null, null, false);
		}

		public function interpret(form:Object):Object{
			Var.pushBindings(rt, RT.map(
					rt.CURRENT_NS, rt.CURRENT_NS.get()
				));
			var expr:Expr = analyze(C.EXPRESSION, form);
			var ret:Object = expr.interpret();
			Var.popBindings(rt);
			return ret;
		}


		/**
		* Don't call this directly. User interface in RT.
		* 
		* @param rdr 
		* @param _onComplete 
		* @param _onFailure 
		* @param _progress 
		* @param sourcePath 
		* @param sourceName 
		* @return
		*/
		public function load(rdr:PushbackReader, _onComplete:Function = null, _onFailure:Function = null, _progress:Function = null, sourcePath:String = null, sourceName:String = null):void{
			var onComplete:Function = _onComplete || function(val:*):void{};
			var onFailure:Function = _onFailure || function(error:*):void{};
			var progress:Function = _progress || function(i:int, j:int):void{};

			var EOF:Object = new Object();
			var forms:Vector = Vector(RT.vector());

			try{
				for( var form:Object = rt.lispReader.read(rdr, false, EOF); form != EOF; form = rt.lispReader.read(rdr, false, EOF)){
					forms = Vector(forms.cons(form));
				}
			}
			catch(e:LispError){
				onFailure(e);
				return;
			}

			var totalLength:int = forms.length;
			var loadAllForms:Function = function(result:*):void{
				if(forms.count() > 0){
					progress(totalLength - forms.length + 1, totalLength);
					try{
						loadForm(forms.shift(), loadAllForms, onFailure);
					}
					catch(e:LispError){
						// Suppress exceptions. We can't handle them for async code anyhow. Just pass back to the toplevel.
						onFailure(e);
					}
				}
				else{
					onComplete(result);
				}
			}

			loadAllForms(null);
		}



		protected function loadForm(form:Object, callback:Function, errorCallback:Function):void{
			// XXX Compiled CUTTLEFISH code stores result of expression here..
			var resultKey:String = _rt.createResultCallback(callback);
			var errorKey:String = _rt.createResultCallback(errorCallback);

			var emitter = new ABCEmitter();
			var scr = emitter.newScript();
			var gen:CodeGen = new CodeGen(this, emitter, scr);

			var expr:Expr = analyze(C.EXPRESSION, form);



			/* Emit bytecode to do the following:
			*
			* - Evaluate 'expr'
			*
			* - Establish a try-catch context around 'expr'
			*   to catch any errors thrown to the top-level
			*
			* - Apply 'callback' to the value of 'expr' or apply
			*   'errorCallback' to the error thrown when evaluating 'expr'
			*/

			gen.pushThisScope();
			gen.pushNewActivationScope();
			gen.cacheRTInstance();


			var tryStart:Object = gen.asm.I_label(undefined);
			expr.emit(C.EXPRESSION, gen);
			gen.callbackWithResult(resultKey);
 			var tryEnd:Object = gen.asm.I_label(undefined);

 			var catchEnd:Object = gen.asm.newLabel();
 			gen.asm.I_jump(catchEnd);

 			var catchStart:Object = gen.asm.I_label(undefined);
 			var excId:int = gen.meth.addException(new ABCException(
 					tryStart.address, 
 					tryEnd.address, 
 					catchStart.address,
 					0, // *
 					gen.emitter.nameFromIdent("toplevelExceptionHandler")
 				));
 			gen.asm.startCatch(); // Increment max stack by 1, for exception object
 			gen.restoreScopeStack(); // Scope stack is wiped on exception, so we reinstate it..
 			gen.pushCatchScope(excId);
 			gen.callbackWithResult(errorKey);
			gen.popScope(); 
			gen.asm.I_returnvoid();
 			gen.asm.I_label(catchEnd);



			var file:ABCFile = emitter.finalize();
			var bytes:ByteArray = file.getBytes();
			bytes.position = 0;
			var swfBytes:ByteArray = ByteLoader.wrapInSWF([bytes]);
			ByteLoader.loadBytes(swfBytes, null, true);
		}

		public function currentNS():LispNamespace{
			return rt.currentNS();
		}

		public function isSpecial(sym:Object):Boolean{
			return rt.isSpecial(sym);
		}

		public function lookupVar(sym:Symbol, internNew:Boolean):Var {
			var v:Var = null;

			//note - ns-qualified vars in other namespaces must already exist
			if(sym.ns != null)
			{
				var nsSym:Symbol = Symbol.intern1(rt, sym.ns);
				var ns:LispNamespace = LispNamespace.find(rt, nsSym);
				if(ns == null) return null;
				//throw new Exception("No such namespace: " + sym.ns);
				var name:Symbol = Symbol.intern1(rt, sym.name);
				if(internNew && ns == currentNS()){
					v = currentNS().intern(name);
				}
				else{
					v = ns.findInternedVar(name);
				}
			}
			else
			{
				//is it mapped?
				var o:Object = currentNS().getMapping(sym);
				if(o == null)
				{
					//introduce a new var in the current ns
					if(internNew){
						v = currentNS().intern(Symbol.intern1(rt, sym.name));
					}
				}
				else if(o is Var)
				{
					v = Var(o);
				}
				else
				{
					throw new Error("Expecting var, but " + sym + " is mapped to " + o);
				}
			}
			if(v != null){
				registerVar(v);
			}
			return v;
		}

		public function registerLocal(num:int, sym:Symbol, init:Expr = null, _lbs:LocalBindingSet = null):LocalBinding{
			var lbs:LocalBindingSet = _lbs || currentLocalBindingSet()
			if(!lbs) throw new Error("IllegalStateException: cannot register local without LocalBindingSet.")
			return lbs.registerLocal(num, sym, init);
		}

		public function registerVar(v:Var):void{
			var id:Object = vars[v];
			if(id == null){
				vars[v] =  registerConstant(v);
			}
		}

		public function registerKeyword(keyword:Keyword):KeywordExpr{
			var id:Object = keywords[keyword];
			if(id == null)
			{
				keywords[keyword] = registerConstant(keyword);
			}
			return new KeywordExpr(this, keyword);
		}
		
		public function registerConstant(o:Object):int{
			constants.push(o);
			return constants.length - 1;
		}

		public function constantName(id:int):String{
			return CONST_PREFIX + id;
		}

		public function constantType(id:int):Class{
			var o:Object = constants[id];
			return Object(o).constructor;
		}

		public function emitVar(gen:CodeGen, aVar:Var):void{
			var i:int = int(vars[aVar]);
			emitConstant(gen, i);
		}

		public function emitKeyword(gen:CodeGen, k:Keyword):void {
			var i:int = int(keywords[k]);
			emitConstant(gen, i);
		}

		public function emitConstant(gen:CodeGen, id:int):void {
			gen.getConstant(id, constantName(id), constantType(id));
		}

		public function analyze(context:C, form:Object, name:String = null):Expr{
			// TODO Re-add line-number tracking here (requires metadata).
			var line:int = int(LINE.get());
			if(RT.meta(form) != null && RT.meta(form).containsKey(_rt.LINE_KEY)){
				line = int(RT.meta(form).valAt(_rt.LINE_KEY));
			}
			Var.pushBindings(_rt, RT.map(LINE, line));
			try{
				//todo symbol macro expansion?
				if(form === null)
				return NilExpr.instance;

				else if(form === RT.T)
				return BooleanExpr.true_instance;

				else if(form === RT.F)
				return BooleanExpr.false_instance;

				else if(form is Symbol)
				return analyzeSymbol(Symbol(form));

				else if(form is Keyword)
				return registerKeyword(Keyword(form));

				else if(form is Number)
				return new NumExpr(Number(form));

				else if(form is String)
				return new StringExpr(this, StringUtil.intern(rt, String(form)));

 				else if(form is ISeq)
 				return analyzeSeq(context, ISeq(form), name);

				else if(form is IVector)
				return VectorExpr.parse(this, context, IVector(form));

				else if(form is IMap)
				return MapExpr.parse(this, context, IMap(form));

				else
				return new ConstantExpr(this, form);

			}
			catch(e:Error)
			{
				var lispError:CompilerError = new CompilerError("CompilerError at " + SOURCE.get() + ":" + int(LINE.get()) + ": " + e.message, e)
				throw lispError;
			}
			finally
			{
				Var.popBindings(_rt);
			}

			return null;
		}


		private function analyzeSymbol(sym:Symbol):Expr{

			if(sym.ns == null) //ns-qualified syms are always Vars
			{
				var b:LocalBinding = referenceLocal(sym);
				if(b != null){
					return new LocalBindingExpr(b);
				}
			}

			var o:Object = resolve(sym);
			if(o is Var)
			{
				var v:Var = Var(o);
				registerVar(v);
				return new VarExpr(this, v);
			}
			else if(o is Class){
				return new ConstantExpr(this, o);
			}
			else{
				throw new Error("Unable to resolve symbol: " + sym + " in this context");
			}
		}


		public function resolve(sym:Symbol):Object{
			return _rt.resolve(sym);
		}

		public function resolveIn(n:LispNamespace, sym:Symbol):Object{
			return _rt.resolveIn(n, sym);
		}

		private function analyzeSeq(context:C, form:ISeq , name:String ):Expr {
			var me:Object = macroexpand1(form);
			if(me != form)
			return analyze(context, me, name);

			var op:Object = RT.first(form);
			if(Util.equal(_rt.FN, op)){
				return FnExpr.parse(this, context, form);
			}
			else if(specialParsers.valAt(op) != null){
				var parse:Function = specialParsers.valAt(op) as Function;
				return parse(this, context, form);
			}
			else{
				return InvokeExpr.parse(this, context, form);
			}
			return null;
		}

		public function macroexpand1(x:Object):Object{
			if(x is ISeq)
			{
				var form:ISeq = ISeq(x);
				var op:Object = RT.first(form);
				if(isSpecial(op))
				return x;
				//macro expansion
				var v:Var = isMacro(op);
				if(v != null)
				{
					return v.apply(Vector.createFromSeq(RT.seq(form.rest())));
				}
			}
			return x;
		}


		public function isMacro(op:Object):Var{
			//no local macros for now
			if(op is Symbol && referenceLocal(Symbol(op)) != null)
			return null;
			if(op is Symbol || op is Var)
			{
				var v:Var  = (op is Var) ? Var(op) : lookupVar(Symbol(op), false);
				if(v != null && v.isMacro())
				{
					if(v.ns != currentNS() && !v.isPublic())
					throw new Error("IllegalStateException: var: " + v + " is not public");
					return v;
				}
			}
			return null;
		}


		public function referenceLocal(sym:Symbol):LocalBinding{
			var bindingSetStack:Vector = Vector(BINDING_SET_STACK.get());
			var len:int = bindingSetStack.count();
			for(var i:int = len - 1; i >= 0; i--){
				var lbs:LocalBindingSet = LocalBindingSet(bindingSetStack.nth(i));
				var b:LocalBinding = LocalBinding(lbs.bindingFor(sym));
				if(b){
					return b;
				}
			}
			return null;
		}

		public function pushLocalBindingSet(set:LocalBindingSet):void{
			var prevStack:Vector = Vector(BINDING_SET_STACK.get());
			var newStack:IVector = prevStack.cons(set);
			Var.pushBindings(rt, RT.map(BINDING_SET_STACK, newStack));
		}

		public function popLocalBindingSet():void{
			Var.popBindings(rt);
		}

		public function currentLocalBindingSet():LocalBindingSet{
			return LocalBindingSet(Vector(BINDING_SET_STACK.get()).peek());
		}


	}
}


import com.cuttlefish.runtime.*;
import com.cuttlefish.util.*;
import com.hurlant.eval.gen.Script;
import com.hurlant.eval.gen.Method;
import com.hurlant.eval.gen.ABCEmitter;
import com.hurlant.eval.gen.AVM2Assembler;
import com.hurlant.eval.abc.ABCSlotTrait;
import com.hurlant.eval.abc.ABCException;
import org.pranaframework.reflection.Type;
import org.pranaframework.reflection.Field;



class C{
	private var _val:String;
	public static const STATEMENT:C = new C("statement");
	public static const EXPRESSION:C = new C("expression");
	public static const RETURN:C = new C("return");
	public static const INTERPRET:C = new C("interpret");

	public function C(str:String){
		_val = str;
	}
	public function toString():String{
		return _val;
	}
}


class CodeGen{
	public var emitter:ABCEmitter;
	public var asm:AVM2Assembler;
	public var scr:Script;
	public var meth:Method;
	public var currentActivation:Object;
	public var cachedRTTempIndex:int = -1;
	public var scopeToLocalMap:Vector;
	protected var _compiler:Compiler;

	public function CodeGen(c:Compiler, emitter:ABCEmitter, scr:Script, meth:Method = null){
		_compiler = c;
		this.emitter = emitter;
		this.scr = scr;
		this.asm = meth ? meth.asm : scr.init.asm;
		this.meth = meth ? meth : scr.init;
		this.scopeToLocalMap = Vector.empty();
	}



	public function newMethodCodeGen(formals:Array, needRest:Boolean, needArguments:Boolean, scopeDepth:int, name:String):CodeGen{
		return new CodeGen(_compiler, this.emitter, this.scr, this.scr.newFunction(formals, needRest, needArguments, scopeDepth, name));
	}



	public function nextActivationSlot():int{
		if(!currentActivation){ throw new Error("IllegalStateException: No activation is current."); }
		var i:int = currentActivation.nextSlot;
		currentActivation.nextSlot += 1;
		return i;
	}

	public function createActivationSlotForLocalBinding(b:LocalBinding):int{
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
		scopeToLocalMap = Vector(scopeToLocalMap.cons(i));
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
		scopeToLocalMap = Vector(scopeToLocalMap.cons(0));
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
		var i:int = int(this.scopeToLocalMap.nth(this.scopeToLocalMap.length - 1));
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
		for each(var i:int in this.scopeToLocalMap){
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
		scopeToLocalMap = Vector(scopeToLocalMap.cons(i));
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
		scopeToLocalMap = Vector(scopeToLocalMap.popEnd());
	}


	/*
	* Stack:   
	*   ... => anRTClass
	*/
	public function getRTClass():void{
		asm.I_getlex(emitter.qname({ns: "com.cuttlefish.runtime", id:"RT"}, false));
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
			asm.I_pushint(emitter.constants.int32(_compiler.rt.instanceId + 1));
			asm.I_nextvalue();
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
		asm.I_pushint(emitter.constants.int32(_compiler.rt.instanceId + 1));
		asm.I_nextvalue();
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
		asm.I_getlex(emitter.qname({ns: "com.cuttlefish.runtime", id:"Vector"}, false))
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





interface Expr{

	function interpret():Object;

	function emit(context:C, gen:CodeGen):void;

}


interface AssignableExpr{

	function interpretAssign(val:Expr):Object;

	function emitAssign(context:C, gen:CodeGen, val:Expr):void;

}


class LiteralExpr implements Expr{

	public function val():Object{ return null }

	public function interpret():Object{
		return val();
	}

	public function emit(context:C, gen:CodeGen):void{}

}




class UntypedExpr implements Expr{

	public function interpret():Object{ throw "SubclassResponsibility";}

	public function emit(context:C, gen:CodeGen):void{ throw "SubclassResponsibility";}

}



class BooleanExpr extends LiteralExpr{
	public static var true_instance:BooleanExpr = new BooleanExpr(true);
	public static var false_instance:BooleanExpr = new BooleanExpr(false);	
	private var _val:Boolean;

	public function BooleanExpr(val:Boolean){
		_val = val;
	}

	override public function val():Object{
		return _val ? RT.T : RT.F;
	}

	override public function emit(context:C, gen:CodeGen):void{
		if(_val){
			gen.asm.I_pushtrue();
		}
		else{
			gen.asm.I_pushfalse();
		}
		if(context == C.STATEMENT){ gen.asm.I_pop();}
	}

}




class StringExpr extends LiteralExpr{
	public var str:String;
	private var _compiler:Compiler;

	public function StringExpr(c:Compiler, str:String){
		this.str = str;
		_compiler = c;
	}

	override public function val():Object{
		return str;
	}

	override public function emit(context:C, gen:CodeGen):void{
		if(context != C.STATEMENT){ gen.asm.I_pushstring( gen.emitter.constants.stringUtf8(str) ); }
	}

}




class NumExpr extends LiteralExpr{
	public var num:Number;

	public function NumExpr(num:Number){
		this.num = num;
	}

	override public function val():Object{
		return this.num;
	}

	override public function emit(context:C, gen:CodeGen):void{
		if(context != C.STATEMENT){ 
			if(this.num is uint){
				gen.asm.I_pushuint(gen.emitter.constants.uint32(this.num));
			}
			else if(this.num is int){
				gen.asm.I_pushint(gen.emitter.constants.int32(this.num));
			}
			else {
				gen.asm.I_pushdouble(gen.emitter.constants.float64(this.num));
			}
		}
	}

}




class ConstantExpr extends LiteralExpr{
	public var v:Object;
	public var id:int;
	private var _compiler:Compiler;

	public function ConstantExpr(c:Compiler, v:Object){
		this.v = v;
		_compiler = c;
		this.id = _compiler.registerConstant(v);
	}

	override public function val():Object{
		return v;
	}

	override public function emit(context:C, gen:CodeGen):void{
		_compiler.emitConstant(gen, id);
		if(context == C.STATEMENT){ gen.asm.I_pop(); }
	}

	public static function parse(c:Compiler, context:C, form:Object):Expr{
		var v:Object = RT.second(form);
		if(v == null){
			return NilExpr.instance;
		}
		else{
			return new ConstantExpr(c, v);
		}

	}
}



class NilExpr extends LiteralExpr{

	public static var instance:NilExpr = new NilExpr();

	override public function val():Object{
		return null;
	}

	override public function emit(context:C, gen:CodeGen):void{
		gen.asm.I_pushnull();
		if(context == C.STATEMENT){ gen.asm.I_pop();}
	}

}



class KeywordExpr implements Expr{
	public var k:Keyword;
	private var _compiler:Compiler;

	public function KeywordExpr(compiler:Compiler, k:Keyword){
		_compiler = compiler;
		this.k = k;
	}

	public function interpret():Object {
		return k;
	}

	public function emit(context:C, gen:CodeGen):void{
		_compiler.emitKeyword(gen, k);
		if(context == C.STATEMENT){ gen.asm.I_pop(); }
	}
}



class VarExpr implements Expr, AssignableExpr{
	public var aVar:Var;
	private var _compiler:Compiler;

	public function VarExpr(c:Compiler, v:Var){
		this.aVar = v;
		_compiler = c;
	}

	public function interpret():Object{
		return aVar.get();
	}

	public function emit(context:C, gen:CodeGen):void{
		_compiler.emitVar(gen, aVar);
		gen.getVar();
		if(context == C.STATEMENT){ gen.asm.I_pop(); }
	}

	public function interpretAssign(val:Expr):Object{
		return aVar.set(val.interpret());
	}

	public function emitAssign(context:C, gen:CodeGen, val:Expr):void{
		_compiler.emitVar(gen, aVar);
		val.emit(C.EXPRESSION, gen);
		gen.setVar();
		if(context == C.STATEMENT) { gen.asm.I_pop(); }
	}
}

class TheVarExpr implements Expr{
	public var aVar:Var;
	private var _compiler:Compiler;

	public function TheVarExpr(c:Compiler, v:Var){
		this.aVar = v;
		_compiler = c;
	}

	public function interpret():Object{
		return aVar;
	}

	public function emit(context:C, gen:CodeGen):void{
		_compiler.emitVar(gen, aVar);
		if(context == C.STATEMENT){ gen.asm.I_pop(); }
	}

	public static function parse(c:Compiler, context:C, form:Object):Expr{
		var sym:Symbol = Symbol(RT.second(form));
		var v:Var = c.lookupVar(sym, false);
		if(v != null)
		return new TheVarExpr(c, v);
		throw new Error("Unable to resolve var: " + sym + " in this context");
	}

}


class IfExpr implements Expr{
	public var testExpr:Expr;
	public var thenExpr:Expr;
	public var elseExpr:Expr;
	private var _compiler:Compiler;

	public function IfExpr(c:Compiler, testExpr:Expr, thenExpr:Expr, elseExpr:Expr ){
		_compiler = c;
		this.testExpr = testExpr;
		this.thenExpr = thenExpr;
		this.elseExpr = elseExpr;
	}

	public function interpret():Object{
		var t:Object = testExpr.interpret();
		if(t != null && t != RT.F){
			return thenExpr.interpret();
		}
		else{
			return elseExpr.interpret();
		}
	}

	public function emit(context:C, gen:CodeGen):void{
		testExpr.emit(C.EXPRESSION, gen);

		/* NOTE: newLabel() will remember the stack depth at the location
		where it is called. So call it when you know the stack depth
		will be the same as that at the corresponding called to I_label()
		*/

		var nullLabel:Object = gen.asm.newLabel();
		var falseLabel:Object = gen.asm.newLabel();
		gen.asm.I_dup();
		gen.asm.I_pushnull();
		gen.asm.I_ifstricteq(nullLabel);
		gen.asm.I_pushfalse();
		gen.asm.I_ifstricteq(falseLabel);

		/* TODO: Is it necessary to coerce_a the return values of the then and else?
		Getting a verification error without the coersion, if return types are different.
		*/

		thenExpr.emit(C.EXPRESSION, gen);
		if(context == C.STATEMENT){ 
			gen.asm.I_pop(); 
		}
		else{
			gen.asm.I_coerce_a();
		}
		var endLabel:Object = gen.asm.newLabel();
		gen.asm.I_jump(endLabel);
		gen.asm.I_label(nullLabel);
		gen.asm.I_pop();
		gen.asm.I_label(falseLabel);
		elseExpr.emit(C.EXPRESSION, gen);
		if(context == C.STATEMENT){ 
			gen.asm.I_pop(); 
		}
		else{
			gen.asm.I_coerce_a();
		}
		gen.asm.I_label(endLabel);
	}

	public static function parse(c:Compiler, context:C, frm:Object):Expr{
		var form:ISeq = ISeq(frm);
		//(if test then) or (if test then else)
		if(form.count() > 4)
		throw new Error("Too many arguments to if");
		else if(form.count() < 3)
		throw new Error("Too few arguments to if");
		return new IfExpr(
			c,
			c.analyze(context == C.INTERPRET ? context : C.EXPRESSION, RT.second(form)),
			c.analyze(context, RT.third(form)),
			c.analyze(context, RT.fourth(form)) // Will result in NilExpr if fourth form is missing.
		);
	}
}



class BodyExpr implements Expr{
	public var exprs:IVector;
	private var _compiler:Compiler;

	public function BodyExpr(c:Compiler, exprs:IVector){
		this.exprs = exprs;
		_compiler = c;
	}

	public static function parse(c:Compiler, context:C, frms:Object):Expr{
		var forms:ISeq = ISeq(frms);
		if(Util.equal(RT.first(forms), c.rt.DO)){
			forms = RT.rest(forms);
		}
		var exprs:IVector = Vector.empty();
		for(; forms != null; forms = forms.rest())
		{
			if(context != C.INTERPRET && (context == C.STATEMENT || forms.rest() != null)){
				exprs = exprs.cons(c.analyze(C.STATEMENT, forms.first()));
			}
			else{
				exprs = exprs.cons(c.analyze(context, forms.first()));
			}
		}
		if(exprs.count() == 0){
			exprs = exprs.cons(NilExpr.instance);
		}
		return new BodyExpr(c, exprs);
	}

	public function interpret():Object{
		var ret:Object = null;
		exprs.each(function(e:Expr):void{
				ret = e.interpret();
			});
		return ret;
	}

	public function emit(context:C, gen:CodeGen):void{
		var len:int = exprs.count();
		for(var i:int = 0; i < len - 1; i++)
		{
			var e:Expr = Expr(exprs.nth(i));
			e.emit(C.STATEMENT, gen);
		}
		var last:Expr = Expr(exprs.nth(len - 1));
		last.emit(context, gen);
	}

}



class DefExpr implements Expr{
	public var aVar:Var;
	public var init:Expr;
	public var initProvided:Boolean;
	public var meta:Expr;
	private var _compiler:Compiler;

	public function DefExpr(compiler:Compiler, inVar:Var, init:Expr, meta:Expr, initProvided:Boolean){
		aVar = inVar;
		this.init = init;
		this.initProvided = initProvided;
		this.meta = meta;
		_compiler = compiler;
	}

	public function interpret():Object{
		if(initProvided){
			aVar.bindRoot(init.interpret());
		}
		return aVar;
	}

	public function emit(context:C, gen:CodeGen):void{
		_compiler.emitVar(gen, aVar);
		if(initProvided)
		{
			gen.asm.I_dup();
			init.emit(C.EXPRESSION, gen);
			gen.bindVarRoot();
		}
		if(meta != null)
		{
			gen.asm.I_dup();
			meta.emit(C.EXPRESSION, gen);
			gen.setMeta();
		}
		if(context == C.STATEMENT){gen.asm.I_pop();}
	}


	public static function parse(compiler:Compiler, context:C, form:Object):Expr{
		//(def x) or (def x initexpr)
		if(RT.count(form) > 3)
		throw new Error("Too many arguments to def");
		else if(RT.count(form) < 2)
		throw new Error("Too few arguments to def");
		else if(!(RT.second(form) is Symbol))
		throw new Error("Second argument to def must be a Symbol");
		var sym:Symbol = Symbol(RT.second(form));

		var v:Var = compiler.lookupVar(sym, true);
		if(v == null){
			throw new Error("Can't refer to qualified var that doesn't exist");
		}

		if(!v.ns.equals(compiler.currentNS())){
			if(sym.ns == null){
				throw new Error("Name conflict, can't def " + sym + " because namespace: " + compiler.currentNS().name + " refers to:" + v);
			}
			else{
				throw new Error("Can't create defs outside of current ns");
			}
		}

		var mm:IMap = sym.meta || RT.map();
		// TODO: Aemon add line info here..
		// mm = IMap(RT.assoc(mm, RT.LINE_KEY, LINE.get()).assoc(RT.FILE_KEY, SOURCE.get()));
		var meta:Expr = compiler.analyze(context == C.INTERPRET ? context : C.EXPRESSION, mm);
		return new DefExpr(compiler, v, compiler.analyze(context == C.INTERPRET ? context : C.EXPRESSION, RT.third(form), v.sym.name), meta, RT.count(form) == 3);
	}

}


class FnMethod{
	public var nameLb:LocalBinding;
	public var params:Vector;
	public var reqParams:Vector;
	public var optionalParams:Vector;
	public var restParam:LocalBinding;
	public var body:BodyExpr;
	public var paramBindings:LocalBindingSet;
	public var startLabel:Object
	private var _compiler:Compiler;
	private var _func:FnExpr;

	public function FnMethod(c:Compiler, f:FnExpr){
		_compiler = c;
		_func = f;
	}

	public static function parse(c:Compiler, context:C, form:ISeq, f:FnExpr):FnMethod{
		var meth:FnMethod = new FnMethod(c, f);
		meth.params = Vector(RT.first(form));
		if(meth.params.count() > Compiler.MAX_POSITIONAL_ARITY){
			throw new Error("Can't specify more than " + Compiler.MAX_POSITIONAL_ARITY + " params");
		}
		meth.reqParams = Vector.empty();
		meth.optionalParams = Vector.empty();
		meth.paramBindings = new LocalBindingSet();
		var state:PSTATE = PSTATE.REQ;
		for(var i:int = 0; i < meth.params.count(); i++)
		{
			var param:Object = meth.params.nth(i);
			var paramSym:Symbol;
			if(param is List) {
				paramSym = Symbol(param.first());
			}
			else if(param is Symbol){
				paramSym = Symbol(param);
			}
			else{			
				throw new Error("IllegalArgumentException: fn params must be Symbols or (Symbol val) pair.");
			}
			if(paramSym.getNamespace() != null)
			throw new Error("Can't use qualified name as parameter: " + paramSym);
			if(param.equals(c.rt._AMP_))
			{
				if(state == PSTATE.REQ || state == PSTATE.OPT)
				state = PSTATE.REST;
				else
				throw new Error("Exception: Invalid parameter list.");
			}
			else
			{
				if(param is List){
					if(state == PSTATE.REQ || state == PSTATE.OPT)
					state = PSTATE.OPT;
					else
					throw new Error("Exception: Invalid parameter list.");
					if(RT.count(param) != 2)
					throw new Error("Exception: Invalid optional parameter pair.");
				}
				switch(state)
				{
					case PSTATE.REQ:
					meth.reqParams = Vector(meth.reqParams.cons(meth.paramBindings.registerLocal(c.rt.nextID(), paramSym)));
					break;

					case PSTATE.OPT:
					meth.optionalParams = Vector(meth.optionalParams.cons(meth.paramBindings.registerLocal(c.rt.nextID(), paramSym, c.analyze(context, RT.second(param)))));
					break;

					case PSTATE.REST:
					meth.restParam = meth.paramBindings.registerLocal(c.rt.nextID(), paramSym);
					state = PSTATE.DONE;
					break;

					default:
					throw new Error("Unexpected parameter");
				}
			}
		}

		var extraBindings:LocalBindingSet = new LocalBindingSet();
		if(f.nameSym){
			// Make this function available to itself..
			meth.nameLb = extraBindings.registerLocal(c.rt.nextID(), f.nameSym);
		}
		var bodyForms:ISeq = ISeq(RT.rest(form));
		c.pushLocalBindingSet(meth.paramBindings);
		c.pushLocalBindingSet(extraBindings);
		Var.pushBindings(c.rt, RT.map(c.RECUR_ARGS, meth.paramBindings));
		meth.body = BodyExpr(BodyExpr.parse(c, C.RETURN, bodyForms));
		Var.popBindings(c.rt);
		c.popLocalBindingSet();
		c.popLocalBindingSet();

		return meth;
	}

	public function emit(context:C, methGen:CodeGen):void{
		methGen.pushThisScope();
		methGen.pushNewActivationScope();
		methGen.cacheRTInstance();

		var i:int = 1;
		reqParams.each(function(b:LocalBinding):void{
				var activationSlot:int = methGen.createActivationSlotForLocalBinding(b);
				methGen.asm.I_getscopeobject(methGen.currentActivation.scopeIndex);
				methGen.asm.I_getlocal(i);
				methGen.asm.I_setslot(activationSlot);
				i++;
			});
		optionalParams.each(function(b:LocalBinding):void{
				var activationSlot:int = methGen.createActivationSlotForLocalBinding(b);
				methGen.asm.I_getscopeobject(methGen.currentActivation.scopeIndex);
				methGen.asm.I_getlocal(i);
				methGen.asm.I_setslot(activationSlot);
				i++;
			});
		if(restParam){
			var restSlot:int = methGen.createActivationSlotForLocalBinding(restParam);
			methGen.asm.I_getscopeobject(methGen.currentActivation.scopeIndex);
			methGen.asm.I_getlocal(i); // get arguments object
			methGen.restFromArguments(i - 1);
			methGen.asm.I_setslot(restSlot);
		}

		var nameSlot:int;
		if(nameLb){
			nameSlot = methGen.createActivationSlotForLocalBinding(nameLb);
			methGen.asm.I_getlocal(i); // get arguments object
 			methGen.asm.I_getproperty(methGen.emitter.nameFromIdent("callee"));
			methGen.asm.I_setlocal(i); // store current function in place of arguments
		}
		
		var loopLabel:Object = methGen.asm.I_label(undefined);
		/* Note: Any instructions after this point will be executed on every recur loop.. */

		if(nameLb){/* We need to re-set name reference on each recur cycle (into fresh activation..)*/
			methGen.asm.I_getscopeobject(methGen.currentActivation.scopeIndex);
			methGen.asm.I_getlocal(i); // get current function object
			methGen.asm.I_setslot(nameSlot);
		}

		Var.pushBindings(_compiler.rt, RT.map(
				_compiler.RECURING_BINDER, this,
				_compiler.RECUR_LABEL, loopLabel
			));
		body.emit(C.RETURN, methGen);
		Var.popBindings(_compiler.rt);

		methGen.asm.I_returnvalue();

	}
	
	
}

class PSTATE{
	public static var REQ:PSTATE = new PSTATE();
	public static var OPT:PSTATE = new PSTATE();
	public static var REST:PSTATE = new PSTATE();
	public static var DONE:PSTATE = new PSTATE();
}
class FnExpr implements Expr{
	public var line:int;
	public var nameSym:Symbol;
	public var methods:IVector;

	private var _compiler:Compiler;

	public function FnExpr(c:Compiler){
		_compiler = c;
	}

	public function get isVariadic():Boolean{
		return methods.count() > 1;
	}

	public static function parse(c:Compiler, context:C, form:ISeq):Expr{
		var f:FnExpr = new FnExpr(c);
		f.line = int(c.LINE.get()); 
		//arglist might be preceded by symbol naming this fn
		if(RT.second(form) is Symbol)
		{
			f.nameSym = Symbol(RT.second(form));
			form = RT.cons(c.rt.FN, RT.rest(RT.rest(form)));
		}

		//now (fn [args] body...) or (fn ([args] body...) ([args2] body2...) ...)
		//turn former into latter
		if(RT.second(form) is IVector){
			form = RT.list(c.rt.FN, RT.rest(form));
		}

		f.methods = Vector.empty();
		for(var s:ISeq = RT.rest(form); s != null; s = RT.rest(s)){
			f.methods = f.methods.cons(FnMethod.parse(c, context, ISeq(s.first()), f));
		}

		return f;
	}


	public function interpret():Object{
		throw new Error("Interpretation not implemented for FnExpr.");
		return null;
	}

	public function emit(context:C, gen:CodeGen):void{
		var name:String = (this.nameSym ? this.nameSym.name : "anonymous") + "_at_" + this.line;
		var methGen:CodeGen;
		if(methods.count() == 1){
			var meth:FnMethod = FnMethod(methods.nth(0));
			var formalsTypes:Array = [];
			meth.reqParams.each(function(ea:Object):void{
					formalsTypes.push(0/*'*'*/); 
				});
			meth.optionalParams.each(function(ea:Object):void{
					formalsTypes.push(0/*'*'*/);
				});
			methGen = gen.newMethodCodeGen(formalsTypes, false, meth.restParam != null || meth.nameLb != null, gen.asm.currentScopeDepth, name);
			if(meth.optionalParams.count() > 0){
				var defaults:Array = meth.optionalParams.map(function(ea:LocalBinding, i:int, a:Array):Object{ return { val: 0, kind: 0x0c } });
				methGen.meth.setDefaults(defaults);
			}
			meth.emit(context, methGen);
			gen.asm.I_newfunction(methGen.meth.finalize());
		}
		else{ // Function is variadic, we must dispatch at runtime to the correct method...

			methGen = gen.newMethodCodeGen([], false, true, gen.asm.currentScopeDepth, name);
			var argsIndex:int = 1;

			// Initialize all the jump labels
			methods.each(function(meth:FnMethod):void{  meth.startLabel = methGen.asm.newLabel(); });

			methods.each(function(meth:FnMethod):void{  
					methGen.asm.I_getlocal(argsIndex);
					methGen.asm.I_getproperty(methGen.emitter.nameFromIdent("length"));
					if(meth.restParam){
						var minArity:int = meth.reqParams.count();
						methGen.asm.I_pushuint(methGen.emitter.constants.uint32(minArity));
						methGen.asm.I_ifge(meth.startLabel);
					}
					else{
						var arity:int = meth.reqParams.count();
						methGen.asm.I_pushuint(methGen.emitter.constants.uint32(arity));
						methGen.asm.I_ifeq(meth.startLabel);
					}
				});

			// If # of params at runtime doesn't match any of the overloads..
			methGen.asm.I_pushstring( methGen.emitter.constants.stringUtf8("Variadic function invoked with invalid arity."));
			methGen.asm.I_throw();

			methods.each(function(meth:FnMethod):void{

					methGen.asm.I_label(meth.startLabel);

					var i:int = argsIndex;
					methGen.asm.I_getlocal(i);
					meth.reqParams.each(function(ea:Object):void{
							methGen.asm.I_dup(); // Keep a copy of the arguments object.
							methGen.asm.I_pushint(methGen.emitter.constants.int32(i));
							methGen.asm.I_nextvalue();
							methGen.asm.I_setlocal(i);
							i++;
						});
					meth.optionalParams.each(function(ea:Object):void{
							methGen.asm.I_dup(); // Keep a copy of the arguments object.
							methGen.asm.I_pushint(methGen.emitter.constants.int32(i));
							methGen.asm.I_nextvalue();
							methGen.asm.I_setlocal(i);
							i++;
						});
					// Now put the arguments object back into the locals, following all the params
					methGen.asm.I_setlocal(i);
					meth.emit(context, methGen);
				});
			
			gen.asm.I_newfunction(methGen.meth.finalize());
		}

		if(context == C.STATEMENT){ gen.asm.I_pop(); }
	}

}



class LetExpr implements Expr{
	public var bindingInits:LocalBindingSet;
	public var body:Expr;
	private var _compiler:Compiler;

	public function LetExpr(c:Compiler, bindingInits:LocalBindingSet, body:Expr){
		_compiler = c;
		this.bindingInits = bindingInits;
		this.body = body;
	}

	public static function parse(c:Compiler, context:C, frm:Object):Expr{
		var form:ISeq = ISeq(frm);
		//(let [var val var2 val2 ...] body...)

		if(!(RT.second(form) is IVector))
		throw new Error("IllegalArgumentException: Bad binding form, expected vector");

		var bindings:IVector = IVector(RT.second(form));
		if((bindings.count() % 2) != 0)
		throw new Error("IllegalArgumentException: Bad binding form, expected matched symbol expression pairs.");

		var body:ISeq = RT.rest(RT.rest(form));

		if(context == C.INTERPRET)
		return c.analyze(context, RT.list(RT.list(c.rt.FN, Vector.empty(), form)));

		var lbs:LocalBindingSet = new LocalBindingSet();
		c.pushLocalBindingSet(lbs);
		for(var i:int = 0; i < bindings.count(); i += 2){
			if(!(bindings.nth(i) is Symbol))
			throw new Error("IllegalArgumentException: Bad binding form, expected symbol, got: " + bindings.nth(i));
			var sym:Symbol = Symbol(bindings.nth(i));
			if(sym.getNamespace() != null)
			throw new Error("Can't let qualified name");
			var init:Expr = c.analyze(C.EXPRESSION, bindings.nth(i + 1), sym.name);
			c.registerLocal(c.rt.nextID(), sym, init);
		}

		var bodyExpr:BodyExpr = BodyExpr(BodyExpr.parse(c, context, body));

		c.popLocalBindingSet();

		return new LetExpr(c, lbs, bodyExpr);
	}


	public function interpret():Object{
		throw new Error("UnsupportedOperationException: Can't eval let/loop");
	}

	public function emit(context:C, gen:CodeGen):void{
		this.bindingInits.eachWithIndex(function(sym:Symbol, b:LocalBinding, i:int){
				if(b){
					var activationSlot:int = gen.createActivationSlotForLocalBinding(b);
					gen.asm.I_getscopeobject(gen.currentActivation.scopeIndex);
					b.init.emit(C.EXPRESSION, gen);
					gen.asm.I_setslot(activationSlot);
				}
			});
		body.emit(context, gen);
	}

}








class InvokeExpr implements Expr{
	public var fexpr:Expr;
	public var args:IVector;
	private var _compiler:Compiler;

	public function InvokeExpr(c:Compiler, fexpr:Expr, args:IVector){
		this.fexpr = fexpr;
		this.args = args;
		_compiler = c;
	}

	public function interpret():Object{
		var fn:Function = Function(fexpr.interpret());
		var argvs:IVector = Vector.empty();
		for(var i:int = 0; i < args.count(); i++){
			argvs = argvs.cons(Expr(args.nth(i)).interpret());
		}
		return fn.apply(null, argvs);
	}

	public function emit(context:C, gen:CodeGen):void{
		fexpr.emit(C.EXPRESSION, gen);
		gen.asm.I_pushnull(); // <-- the receiver
		for(var i:int = 0; i < Math.min(Compiler.MAX_POSITIONAL_ARITY, args.count()); i++)
		{
			var e:Expr = Expr(args.nth(i));
			e.emit(C.EXPRESSION, gen);
		}

		// TODO: Aemon, do this.
		// 		if(args.count() > MAX_POSITIONAL_ARITY)
		// 		{
			// 			PersistentVector restArgs = PersistentVector.EMPTY;
			// 			for(int i = MAX_POSITIONAL_ARITY; i < args.count(); i++)
			// 			{
				// 				restArgs = restArgs.cons(args.nth(i));
				// 			}
			// 			MethodExpr.emitArgsAsArray(restArgs, fn, gen);
			// 		}

		// TODO: For recursion?
		// 		if(context == C.RETURN)
		// 		{
		// 			FnMethod method = (FnMethod) METHOD.get();
		// 			method.emitClearLocals(gen);
		// 		}
		gen.asm.I_call(args.count());
		if(context == C.STATEMENT){ gen.asm.I_pop(); }
	}

	public static function parse(c:Compiler, context:C, form:ISeq):Expr{
		if(context != C.INTERPRET){
			context = C.EXPRESSION;
		}
		var fexpr:Expr = c.analyze(context, form.first());
		var args:IVector = Vector.empty();
		for(var s:ISeq = RT.seq(form.rest()); s != null; s = s.rest())
		{
			args = args.cons(c.analyze(context, s.first()));
		}

		if(args.count() > Compiler.MAX_POSITIONAL_ARITY){ throw new Error("IllegalStateException: Invoking Arity greater than " + Compiler.MAX_POSITIONAL_ARITY + " not supported"); }

		return new InvokeExpr(c, fexpr, args);
	}
}


class LocalBindingSet{

	private var _lbs:IVector;
	
	public function LocalBindingSet(){
		_lbs = RT.vector();
	}

	public function count():int{
		return _lbs.count();
	}

	public function bindingFor(sym:Symbol):LocalBinding{
		for(var i:int = _lbs.length - 1; i > -1; i--){
			var lb:LocalBinding = _lbs[i];
			if(Util.equal(lb.sym, sym)){
				return lb;
			}
		}
		return null;
	}

	public function registerLocal(num:int, sym:Symbol, init:Expr = null):LocalBinding{
		var lb:LocalBinding = new LocalBinding(num, sym, init);
		_lbs = _lbs.cons(lb);
		return lb;
	}

	public function each(iterator:Function):void{
		_lbs.each(function(lb:LocalBinding):void{
				iterator(lb.sym, lb);
			});
	}

	public function eachWithIndex(iterator:Function):void{
		var i:int = 0;
		_lbs.each(function(lb:LocalBinding):void{
				iterator(lb.sym, lb, i);
				i += 1;
			});
	}

	public function eachReversedWithIndex(iterator:Function):void{
		for(var i:int = _lbs.length - 1; i > -1; i--){
			var lb:LocalBinding = _lbs[i];
			iterator(lb.sym, lb, i);
		}
	}
	
}


class LocalBinding{
	public var sym:Symbol;
	public var runtimeName:String;
	public var slotIndex:int;
	public var init:Expr;

	public function LocalBinding(num:int, sym:Symbol, init:Expr = null){
		this.sym = sym;
		this.runtimeName = "local" + num;
		this.init = init;
	}

}


class LocalBindingExpr implements Expr{
	public var b:LocalBinding;

	public function LocalBindingExpr(b:LocalBinding){
		this.b = b;
	}

	public function interpret():Object{
		throw new Error("UnsupportedOperationException: Can't interpret locals");
	}

	public function emit(context:C, gen:CodeGen):void{
		if(context != C.STATEMENT){
			gen.asm.I_getlex(gen.emitter.qname({ns: "", id: b.runtimeName}, false));
		}
	}
}




class AssignExpr implements Expr{
	public var target:AssignableExpr;
	public var val:Expr;

	public function AssignExpr(target:AssignableExpr, val:Expr){
		this.target = target;
		this.val = val;
	}

	public function interpret():Object{
		return target.interpretAssign(val);
	}

	public function emit(context:C, gen:CodeGen):void{
		target.emitAssign(context, gen, val);
	}

	public static function parse(c:Compiler, context:C, frm:Object):Expr{
		var form:ISeq = ISeq(frm);
		if(RT.length(form) != 3)
		throw new Error("IllegalArgumentException: Malformed assignment, expecting (set! target val)");
		var target:Expr = c.analyze(C.EXPRESSION, RT.second(form));
		if(!(target is AssignableExpr))
		throw new Error("IllegalArgumentException: Invalid assignment target");
		return new AssignExpr(AssignableExpr(target), c.analyze(C.EXPRESSION, RT.third(form)));
	}
}




class VectorExpr implements Expr{
	public var args:IVector;

	public function VectorExpr(args:IVector){
		this.args = args;
	}

	public function interpret():Object{
		var ret:IVector = Vector.empty();
		for(var i:int = 0; i < args.count(); i++)
		ret = IVector(ret.cons(Expr(args.nth(i)).interpret()));
		return ret;
	}

	public function emit(context:C, gen:CodeGen):void{
		gen.getRTClass();
		for(var i:int = 0; i < args.count(); i++){
			Expr(args.nth(i)).emit(context, gen);
		}
		gen.newVector(this.args.count());
		if(context == C.STATEMENT) { gen.asm.I_pop();}
	}

	public static function parse(c:Compiler, context:C, form:IVector):Expr{
		var args:IVector = Vector.empty();
		for(var i:int = 0; i < form.count(); i++)
		args = IVector(args.cons(c.analyze(context == C.INTERPRET ? context : C.EXPRESSION, form.nth(i))));
		return new VectorExpr(args);
	}

}




class MapExpr implements Expr{
	public var keyvals:IVector;

	public function MapExpr(keyvals:IVector){
		this.keyvals = keyvals;
	}

	public function interpret():Object{
		var m:IMap = RT.map();
		for(var i:int = 0; i < keyvals.count(); i += 2){
			var key:Object = Expr(keyvals.nth(i)).interpret();
			var val:Object = Expr(keyvals.nth(i + 1)).interpret();
			m = m.assoc(key, val);
		}
		return m;
	}

	public function emit(context:C, gen:CodeGen):void{
		gen.getRTClass();
		for(var i:int = 0; i < keyvals.count(); i++){
			Expr(keyvals.nth(i)).emit(context, gen);
		}
		gen.newMap(this.keyvals.count());
		if(context == C.STATEMENT) { gen.asm.I_pop();}
	}

	public static function parse(c:Compiler, context:C, form:IMap):Expr{
		var keyvals:Vector = new Vector([]);
		form.each(function(key:Object, val:Object):void{
				keyvals.push(c.analyze(context == C.INTERPRET ? context : C.EXPRESSION, key));
				keyvals.push(c.analyze(context == C.INTERPRET ? context : C.EXPRESSION, val));
			});
		return new MapExpr(keyvals);
	}
}




class RecurExpr implements Expr{
	public var args:IVector;
	public var loopLocals:LocalBindingSet;
	private var _compiler:Compiler;

	public function RecurExpr(c:Compiler, loopLocals:LocalBindingSet, args:IVector){
		_compiler = c;
		this.loopLocals = loopLocals;
		this.args = args;
	}

	public function interpret():Object{
		throw new Error("UnsupportedOperationException: Can't eval recur");
	}

	public function emit(context:C, gen:CodeGen):void{
		var loopLabel:Object = _compiler.RECUR_LABEL.get();
		if(loopLabel == null){
			throw new Error("IllegalStateException: No loop label found for recur.");
		}

		// First push all the evaluated recur args onto the stack
		this.loopLocals.eachWithIndex(function(sym:Symbol, lb:LocalBinding, i:int){
				var arg:Expr = Expr(args.nth(i));
				arg.emit(C.EXPRESSION, gen);
			});

		
		// if binding form is a function, replace the current activation with a fresh one
		if(_compiler.RECURING_BINDER.get() is FnMethod){
			gen.refreshCurrentActivationScope();
		}

		// then fill it up with the recur args.
		this.loopLocals.eachReversedWithIndex(function(sym:Symbol, lb:LocalBinding, i:int){
				gen.asm.I_getscopeobject(gen.currentActivation.scopeIndex);
				gen.asm.I_swap();
				gen.asm.I_setslot(lb.slotIndex);
			});
		gen.asm.I_jump(loopLabel);
	}


	public static function parse(c:Compiler, context:C, frm:Object):Expr{
		var form:ISeq = ISeq(frm);
		var loopLocals:LocalBindingSet = LocalBindingSet(c.RECUR_ARGS.get());
		if(context != C.RETURN || loopLocals == null)
		throw new Error("UnsupportedOperationException: Can only recur from tail position. Found in context: " + context);
		if(c.IN_CATCH_FINALLY.get())
		throw new Error("UnsupportedOperationException: Cannot recur from catch/finally");
		var args:IVector = Vector.empty();
		for(var s:ISeq = RT.seq(form.rest()); s != null; s = s.rest())
		{
			args = args.cons(c.analyze(C.EXPRESSION, s.first()));
		}
		if(args.count() != loopLocals.count())
		throw new Error("IllegalArgumentException: Mismatched argument count to recur, expected: " + loopLocals.count() + " args, got:" + args.count());
		return new RecurExpr(c, loopLocals, args);
	}
}



class HostExpr implements Expr{

	public function emit(context:C, gen:CodeGen):void{
		
	}

	public function interpret():Object {

		return null;
	}

	public static function parse(compiler:Compiler, context:C, frm:Object):Expr{
		var form:ISeq = ISeq(frm);
		//(. x fieldname-sym) or
		// (. x (methodname-sym args?))
		if(RT.length(form) < 3)
		throw new Error("IllegalArgumentException: Malformed member expression, expecting (. target field) or (. target (method args*))");

		var sym:Symbol;
		var c:Class;
		var instance:Expr;
		if(RT.length(form) == 3 && RT.third(form) is Symbol)    //field
		{
			sym = Symbol(RT.third(form));

			//determine static or instance
			//static target must be symbol, either fully.qualified.Classname or Classname that has been imported
			c = maybeClass(compiler, RT.second(form), false);
			if(c != null)
			return new StaticFieldExpr(compiler, c, sym.name);
			
			instance = compiler.analyze(context == C.INTERPRET ? context : C.EXPRESSION, RT.second(form));
			return new InstanceFieldExpr(compiler, instance, sym.name);
		}
		else // method call
		{
			var call:ISeq = ISeq(RT.third(form))
			if(!(RT.first(call) is Symbol))
			throw new Error("IllegalArgumentException: Malformed member expression");

			sym = Symbol(RT.first(call));

			var args:IVector = Vector.empty();
			for(var s:ISeq = RT.rest(call); s != null; s = s.rest()){
				args = args.cons(compiler.analyze(context == C.INTERPRET ? context : C.EXPRESSION, s.first()));
			}

			c = maybeClass(compiler, RT.second(form), false);
			if(c != null)
			return new StaticMethodExpr(compiler, c, sym.name, args);

			instance = compiler.analyze(context == C.INTERPRET ? context : C.EXPRESSION, RT.second(form));
			return new InstanceMethodExpr(compiler, instance, sym.name, args);
		}
	}

	public static function maybeClass(compiler:Compiler, form:Object, stringOk:Boolean):Class{
		if(form is Class)
		return Class(form);
		var c:Class = null;
		if(form is Symbol)
		{
			var sym:Symbol = Symbol(form);
			if(sym.ns == null) //if ns-qualified can't be classname
			{
				if(sym.name.indexOf('.') > 0 || sym.name.charAt(0) == '['){
						c = compiler.rt.classForName(sym.name);
					}
					else
					{
						var o:Object = compiler.currentNS().getMapping(sym);
						if(o is Class)
						c = Class(o);
					}
				}
			}
			else if(stringOk && form is String)
			c = compiler.rt.classForName(String(form));
			return c;
		}


	}



	class StaticMethodExpr extends HostExpr{
		public var methName:String;
		public var c:Class;
		public var classId:int;
		public var args:IVector;
		private var _compiler:Compiler;

		public function StaticMethodExpr(compiler:Compiler, c:Class, methName:String, args:IVector){
			_compiler = compiler;
			this.methName = methName;
			this.c = c;
			this.classId = _compiler.registerConstant(c);
			this.args = args;
		}

		override public function interpret():Object{
			return c[this.methName].apply(null, args.collect(function(ea:*):*{ return ea.interpret(); }));
		}

		override public function emit(context:C, gen:CodeGen):void{
			_compiler.emitConstant(gen, this.classId);
			this.args.each(function(ea:Expr):void{ ea.emit(C.EXPRESSION, gen); })
			gen.asm.I_callproperty(gen.emitter.nameFromIdent(this.methName), args.count());
			if(context == C.STATEMENT){ gen.asm.I_pop(); }
		}

	}


	class InstanceMethodExpr extends HostExpr{
		public var methName:String;
		public var target:Expr;
		public var args:IVector;
		private var _compiler:Compiler;

		public function InstanceMethodExpr(compiler:Compiler, target:Expr, methName:String, args:IVector){
			_compiler = compiler;
			this.methName = methName;
			this.target = target;
			this.args = args;
		}

		override public function interpret():Object{
			return (target.interpret())[this.methName].apply(null, args.collect(function(ea:*):*{ return ea.interpret(); }));
		}

		override public function emit(context:C, gen:CodeGen):void{
			target.emit(C.EXPRESSION, gen);
			this.args.each(function(ea:Expr):void{ ea.emit(C.EXPRESSION, gen); })
			gen.asm.I_callproperty(gen.emitter.nameFromIdent(this.methName), args.count());
			if(context == C.STATEMENT){ gen.asm.I_pop(); }
		}

	}




	class StaticFieldExpr extends HostExpr implements AssignableExpr{
		public var fieldName:String;
		public var c:Class;
		public var classId:int;
		private var _compiler:Compiler;

		public function StaticFieldExpr(compiler:Compiler, c:Class, fieldName:String){
			_compiler = compiler;
			this.fieldName = fieldName;
			this.c = c;
			this.classId = _compiler.registerConstant(c);
		}

		override public function interpret():Object{
			return c[this.fieldName];
		}

		public function interpretAssign(val:Expr):Object{
			return c[this.fieldName] = val.interpret();
		}


		override public function emit(context:C, gen:CodeGen):void{
			_compiler.emitConstant(gen, classId);
			gen.asm.I_getproperty(gen.emitter.nameFromIdent(this.fieldName));
			if(context == C.STATEMENT){ gen.asm.I_pop(); }
		}


		public function emitAssign(context:C, gen:CodeGen, val:Expr):void{
			_compiler.emitConstant(gen, classId);
			gen.asm.I_dup();
			val.emit(C.EXPRESSION, gen);
			gen.asm.I_setproperty(gen.emitter.nameFromIdent(this.fieldName));
			if(context == C.STATEMENT){ gen.asm.I_pop(); }
		}
	}



	class InstanceFieldExpr extends HostExpr implements AssignableExpr{
		public var fieldName:String;
		public var target:Expr;
		private var _compiler:Compiler;

		public function InstanceFieldExpr(compiler:Compiler, target:Expr, fieldName:String){
			_compiler = compiler;
			this.target = target;
			this.fieldName = fieldName;
		}

		override public function interpret():Object{
			return this.target[this.fieldName];
		}

		public function interpretAssign(val:Expr):Object{
			return this.target[this.fieldName] = val.interpret();
		}

		override public function emit(context:C, gen:CodeGen):void{
			target.emit(C.EXPRESSION, gen);
			gen.asm.I_getproperty(gen.emitter.nameFromIdent(this.fieldName));
			if(context == C.STATEMENT){ gen.asm.I_pop(); }
		}


		public function emitAssign(context:C, gen:CodeGen, val:Expr):void{
			target.emit(C.EXPRESSION, gen);
			gen.asm.I_dup();
			val.emit(C.EXPRESSION, gen);
			gen.asm.I_setproperty(gen.emitter.nameFromIdent(this.fieldName));
			if(context == C.STATEMENT){ gen.asm.I_pop(); }
		}
	}


	class NewExpr implements Expr{
		public var args:IVector;
		public var target:Expr;
		private var _compiler:Compiler;

		public function NewExpr(compiler:Compiler, target:Expr, args:IVector){
			this.args = args;
			this.target = target;
			_compiler = compiler;
		}

		public function interpret():Object{
			throw new Error("Interpretation of NewExpr not supported.");
		}

		public function emit(context:C, gen:CodeGen):void{
			target.emit(C.EXPRESSION, gen);
			this.args.each(function(ea:Expr):void{ ea.emit(C.EXPRESSION, gen); });
			gen.asm.I_construct(args.count());
			if(context == C.STATEMENT){ gen.asm.I_pop(); }
		}

		public static function parse(compiler:Compiler, context:C, frm:Object):Expr{
			var form:ISeq = ISeq(frm);
			//(new classExpr args...)
			if(form.count() < 2)
			throw new Error("Wrong number of arguments, expecting: (new classExpr args...)");
			var target:Expr = compiler.analyze(C.EXPRESSION, RT.second(form));
			var args:IVector = Vector.empty();
			for(var s:ISeq = RT.rest(RT.rest(form)); s != null; s = s.rest()){
				args = args.cons(compiler.analyze(C.EXPRESSION, s.first()));
			}
			return new NewExpr(compiler, target, args);
		}
	}


	class ThrowExpr extends UntypedExpr{
		public var excExpr:Expr;

		public function ThrowExpr(excExpr:Expr){
			this.excExpr = excExpr;
		}

		override public function interpret():Object{
			throw new Error("Can't interpret a throw.");
		}

		override public function emit(context:C, gen:CodeGen):void{
			// So there's a nil on the stack after the exception is thrown,
			// required so that in the event that the try is prematurely aborted (because of
			// this throw) there will still be something on the stack to match the catch's
			// result.
			gen.asm.I_pushnull();
			// Then, reconcile with type of ensuing catch expr...
			gen.asm.I_coerce_a(); 
			excExpr.emit(context, gen);
			gen.asm.I_throw();
		}

		public static function parse(c:Compiler, context:C, form:Object):Expr{
			if(context == C.INTERPRET)
			return c.analyze(context, RT.list(RT.list(c.rt.FN, Vector.empty(), form)));
			return new ThrowExpr(c.analyze(context, RT.second(form)));
		}

	}


	class CatchClause{
		//final String className;
		public var c:Class;
		public var className:String;
		public var lb:LocalBinding;
		public var handler:Expr;
		public var label:Object;
		public var endLabel:Object;

		public function CatchClause(c:Class, className:String, lb:LocalBinding, handler:Expr){
			this.c = c;
			this.lb = lb;
			this.handler = handler;
			this.className = className;
		}
	}


	class TryExpr implements Expr{
		public var tryExpr:Expr;
		public var catchExprs:IVector;
		public var finallyExpr:Expr;
		private var _compiler:Compiler;


		public function TryExpr(c:Compiler, tryExpr:Expr, catchExprs:IVector, finallyExpr:Expr){
			_compiler = c;
			this.tryExpr = tryExpr;
			this.catchExprs = catchExprs;
			this.finallyExpr = finallyExpr;
		}

		public function interpret():Object{
			throw new Error("UnsupportedOperationException: Can't eval try");
		}

		public function emit(context:C, gen:CodeGen):void{			
			var endClauses:Object = gen.asm.newLabel();
			var finallyLabel:Object = gen.asm.newLabel();
			var end:Object = gen.asm.newLabel();
			for(var i:int = 0; i < catchExprs.count(); i++)
			{
				var clause:CatchClause = CatchClause(catchExprs.nth(i));
				clause.label = gen.asm.newLabel();
				clause.endLabel = gen.asm.newLabel();
			}
			var tryStart:Object = gen.asm.I_label(undefined);
			tryExpr.emit(context, gen);
			gen.asm.I_coerce_a(); // Reconcile with return type of catch expr..
			var tryEnd:Object = gen.asm.I_label(undefined);
			if(finallyExpr != null){
				gen.asm.I_pop();
				gen.asm.I_jump(finallyLabel);
			}
			else{
				gen.asm.I_jump(end);
			}
			var catchStart:Object = gen.asm.I_label(undefined);

			if(catchExprs.count() > 0){
				var excId:int = gen.meth.addException(new ABCException(
						tryStart.address, 
						tryEnd.address, 
						catchStart.address, 
						0, // *
						gen.emitter.nameFromIdent("name")
					));

				gen.asm.startCatch(); // Increment max stack by 1, for exception object
				gen.restoreScopeStack(); // Scope stack is wiped on exception, so we reinstate it..
				gen.pushCatchScope(excId); 

				
				for(i = 0; i < catchExprs.count(); i++)
				{
					clause = CatchClause(catchExprs.nth(i));
					gen.asm.I_label(clause.label);

					
					// Exception object should be on top of operand stack...
					gen.asm.I_dup();
					gen.asm.I_istype(gen.emitter.nameFromIdent(clause.className));
					gen.asm.I_iffalse(clause.endLabel);


					// Store the exception in an activation slot..
					var b:LocalBinding = clause.lb;
					var activationSlot:int = gen.createActivationSlotForLocalBinding(b);
					gen.asm.I_getscopeobject(gen.currentActivation.scopeIndex);
					gen.asm.I_swap(); 
					gen.asm.I_setslot(activationSlot); 

					clause.handler.emit(context, gen);
					gen.asm.I_coerce_a();// Reconcile with return type of preceding try expr..

					gen.asm.I_jump(endClauses);

					gen.asm.I_label(clause.endLabel);
				}
				// If none of the catch clauses apply, rethrow the exception.
				gen.asm.I_throw();

				gen.asm.I_label(endClauses);
				// Pop the catch scope..
				gen.popScope(); 
				if(finallyExpr != null){
					gen.asm.I_pop();
					gen.asm.I_jump(finallyLabel);
				}
				else{
					gen.asm.I_jump(end);
				}

			}
			if(finallyExpr != null)
			{
				gen.asm.I_label(finallyLabel);
				finallyExpr.emit(context, gen);
				gen.asm.I_coerce_a();// Reconcile with return types of preceding try/catch exprs..
			}
			gen.asm.I_label(end);
			if(context == C.STATEMENT){ gen.asm.I_pop(); }

		}


		public static function parse(c:Compiler, context:C, frm:Object):Expr{
			var form:ISeq = ISeq(frm);
			if(context != C.RETURN)
			return c.analyze(context, RT.list(RT.list(c.rt.FN, Vector.empty(), form)));

			//(try try-expr* catch-expr* finally-expr?)
			//catch-expr: (catch class sym expr*)
			//finally-expr: (finally expr*)

			var body:IVector = Vector.empty();
			var catches:IVector = Vector.empty();
			var finallyExpr:Expr = null;
			var caught:Boolean = false;

			for(var fs:ISeq = form.rest(); fs != null; fs = fs.rest())
			{
				var f:Object = fs.first();
				var op:Object = (f is ISeq) ? ISeq(f).first() : null;
				if(!Util.equal(op, c.rt.CATCH) && !Util.equal(op, c.rt.FINALLY))
				{
					if(caught)
					throw new Error("Only catch or finally clause can follow catch in try expression");
					body = body.cons(f);
				}
				else
				{
					if(Util.equal(op, c.rt.CATCH))
					{
						var className:Symbol = Symbol(RT.second(f));
						var klass:Class = HostExpr.maybeClass(c, className, false);
						if(klass == null)
						throw new Error("IllegalArgumentException: Unable to resolve classname: " + RT.second(f));
						if(!(RT.third(f) is Symbol))
						throw new Error("IllegalArgumentException: Bad binding form, expected symbol, got: " + RT.third(f));
						var sym:Symbol = Symbol(RT.third(f));
						if(sym.getNamespace() != null)
						throw new Error("Can't bind qualified name:" + sym);

						c.pushLocalBindingSet(new LocalBindingSet());
						var lb:LocalBinding = c.registerLocal(c.rt.nextID(), sym);
						Var.pushBindings(c.rt, RT.map(c.IN_CATCH_FINALLY, true));
						var handler:Expr = BodyExpr.parse(c, context, RT.rest(RT.rest(RT.rest(f))));
						Var.popBindings(c.rt);
						c.popLocalBindingSet();

						catches = catches.cons(new CatchClause(klass, className.toString(), lb, handler));
						caught = true;
					}
					else //finally
					{
						if(fs.rest() != null)
						throw new Error("Finally clause must be last in try expression");
						Var.pushBindings(c.rt, RT.map(c.IN_CATCH_FINALLY, true));
						finallyExpr = BodyExpr.parse(c, C.STATEMENT, RT.rest(f));
						Var.popBindings(c.rt);
					}
				}
			}

			return new TryExpr(c, BodyExpr.parse(c, context, RT.seq(body)), catches, finallyExpr);
		}
	}


