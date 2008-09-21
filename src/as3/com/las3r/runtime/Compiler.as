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

package com.las3r.runtime{
	import com.las3r.util.*;
	import com.las3r.jdk.io.PushbackReader;
	import flash.utils.getQualifiedClassName;
	import flash.utils.ByteArray;
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

		private var _bindingSetStack:IVector;
		private var _loopLocalsStack:IVector;
		private var _loopLabelStack:IVector;
		private var _inCatchFinally:Boolean = false;
		private var _rt:RT;
		public var specialParsers:IMap;

		public function get rt():RT{ return _rt; }
		public function get constants():Array{ return _rt.constants; }
		public function get keywords():IMap{ return _rt.keywords; }
		public function get vars():IMap{ return _rt.vars; }

		public function Compiler(rt:RT){
			_rt = rt;

			specialParsers = RT.map(
				_rt.DEF, DefExpr.parse,
				_rt.LOOP, LetExpr.parse,
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

		}

		public function interpret(form:Object):Object{
			RT.instance = rt;
			Var.pushBindings(rt, RT.map(
					rt.CURRENT_NS, rt.CURRENT_NS.get()
				));
			var expr:Expr = analyze(C.EXPRESSION, form);
			var ret:Object = expr.interpret();
			Var.popBindings(rt);
			return ret;
		}


		public function load(rdr:PushbackReader, onComplete:Function = null, sourcePath:String = null, sourceName:String = null):void{
			var callback:Function = onComplete || function(val:*):void{};

			var EOF:Object = new Object();
			var forms:Vector = Vector(RT.vector());
			for( var form:Object = rt.lispReader.read(rdr, false, EOF); form != EOF; form = rt.lispReader.read(rdr, false, EOF)){
				forms.cons(form);
			}

			Var.pushBindings(rt, 
				RT.map(
					rt.CURRENT_NS, rt.CURRENT_NS.get()
				)
			);
			var loadAllForms:Function = function(result:*):void{
				if(forms.count() > 0){
					loadForm(forms.shift(), loadAllForms);
				}
				else{
					Var.popBindings(rt);
					onComplete(result);
				}
			}
			loadAllForms(null);
		}

		protected function loadForm(form:Object, callback:Function):void{

			// XXX Compiled LAS3R code looks here for active RT instance...
			RT.instance = rt;

			// XXX Compiled LAS3R code stores result of expression here..
			var resultKey:String = "load_result_" + _rt.nextID();

			_bindingSetStack = RT.vector();
			_loopLabelStack = RT.vector();
			_loopLocalsStack = RT.vector();

			var emitter = new ABCEmitter();
			var scr = emitter.newScript();
			var gen:CodeGen = new CodeGen(emitter, scr);

			var expr:Expr = analyze(C.STATEMENT, form);

			// Emit the bytecode..
			gen.pushThisScope();
			gen.pushNewActivationScope();
			expr.emit(C.EXPRESSION, gen);
			gen.storeResult(resultKey);

			var file:ABCFile = emitter.finalize();
			var bytes:ByteArray = file.getBytes();
			bytes.position = 0;
			var swfBytes:ByteArray = ByteLoader.wrapInSWF([bytes]);

			// Debug
			rt.debugFunc(ABCDump.dump(swfBytes));

			bytes.position = 0;
			ByteLoader.loadBytes(bytes, function(e:Event):void{
					callback(_rt.getResult(resultKey));
				}
			);	
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
			var lbs:LocalBindingSet = _lbs || LocalBindingSet(_bindingSetStack.peek());
			if(!lbs) throw new Error("IllegalStateException: cannot register local without LocalBindingSet.")
			return lbs.registerLocal(num, sym, init);
		}

		public function registerVar(v:Var):void{
			var id:Object = RT.get(vars, v);
			if(id == null){
				RT.assoc(vars, v, registerConstant(v));
			}
		}

		public function registerKeyword(keyword:Keyword):KeywordExpr{
			var id:Object = RT.get(keywords, keyword);
			if(id == null)
			{
				RT.assoc(keywords, keyword, registerConstant(keyword));
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
			var i:int = int(vars.valAt(aVar));
			emitConstant(gen, i);
		}

		public function emitKeyword(gen:CodeGen, k:Keyword):void {
			var i:int = int(keywords.valAt(k));
			emitConstant(gen, i);
		}

		public function emitConstant(gen:CodeGen, id:int):void {
			gen.getConstant(id, constantName(id), constantType(id));
		}

		public function analyze(context:C, form:Object, name:String = null):Expr{
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
			// TODO Re-add line-number tracking here (requires metadata).

			var me:Object = macroexpand1(form);
			if(me != form)
			return analyze(context, me, name);

			var op:Object = RT.first(form);
			if(op.equals(_rt.FN)){
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
					return v.apply(Vector.createFromSeq(form.rest()));
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
			var len:int = _bindingSetStack.count();
			for(var i:int = len - 1; i >= 0; i--){
				var lbs:LocalBindingSet = LocalBindingSet(_bindingSetStack.nth(i));
				var b:LocalBinding = LocalBinding(lbs.bindingFor(sym));
				if(b){
					return b;
				}
			}
			return null;
		}


		public function pushLocalBindingSet(set:LocalBindingSet):void{
			_bindingSetStack.cons(set);
		}
		public function popLocalBindingSet():void{
			_bindingSetStack.popEnd();
		}



		public function pushLoopLabel(label:Object):void{
			_loopLabelStack.cons(label);
		}
		public function popLoopLabel():void{
			_loopLabelStack.popEnd();
		}
		public function get currentLoopLabel():Object{
			return _loopLabelStack.peek();
		}



		public function pushLoopLocals(lbs:LocalBindingSet):void{
			_loopLocalsStack.cons(lbs);
		}
		public function popLoopLocals():void{
			LocalBindingSet(_loopLocalsStack.popEnd());
		}
		public function get currentLoopLocals():LocalBindingSet{
			return LocalBindingSet(_loopLocalsStack.peek());
		}



		public function get inCatchFinally():Boolean{
			return _inCatchFinally;
		}
		public function set inCatchFinally(val:Boolean):void{
			_inCatchFinally = val;
		}


	}
}


import com.las3r.runtime.*;
import com.las3r.util.*;
import com.hurlant.eval.gen.Script;
import com.hurlant.eval.gen.Method;
import com.hurlant.eval.gen.ABCEmitter;
import com.hurlant.eval.gen.AVM2Assembler;
import com.hurlant.eval.ast.PublicNamespace;
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
	public var scopeToLocalMap:Vector;

	public function CodeGen(emitter:ABCEmitter, scr:Script, meth:Method = null){
		this.emitter = emitter;
		this.scr = scr;
		this.asm = meth ? meth.asm : scr.init.asm;
		this.meth = meth ? meth : scr.init;
		this.scopeToLocalMap = Vector.empty();
	}



	public function newMethodCodeGen(formals:Array, needRest:Boolean, needArguments:Boolean, scopeDepth:int):CodeGen{
		return new CodeGen(this.emitter, this.scr, this.scr.newFunction(formals, needRest, needArguments, scopeDepth));
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
		var i:int = asm.getTemp()
		asm.I_setlocal(i);
		this.scopeToLocalMap.cons(i);
	}


	/*
	* For the current method, push 'this', stored by default in register 0, onto the scope stack.
	*
	* Stack:   
	*   ... => ...
	*/
	public function pushThisScope():void{
		asm.I_getlocal_0();
		asm.I_dup();
		asm.I_pushscope();
		var i:int = asm.getTemp()
		asm.I_setlocal(i);
		this.scopeToLocalMap.cons(i);
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
		scopeToLocalMap.cons(i);
	}

	/*
	* Pop the scope stack.
	*
	* Stack:   
	*   ... => ...
	*/
	public function popScope():void{
		asm.I_popscope();
		asm.killTemp(scopeToLocalMap.popEnd());
	}


	/*
	* Stack:   
	*   ... => anRTClass
	*/
	public function getRTClass():void{
		asm.I_getlex(emitter.qname({ns: new PublicNamespace("com.las3r.runtime"), id:"RT"}, false));
	}



	/*
	* Get the current, active instance of RT.
	*
	* Stack:   
	*   ... => anRT
	*/
	protected function getRT():void{
		getRTClass();
		asm.I_getproperty(emitter.nameFromIdent("instance"));
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
		asm.I_callproperty(emitter.nameFromIdent("traceOut"), 1);
	}


	/*
	* Store the value at TOS at key in RT.
	* Stack:   
	*   val => ...
	*/
	public function storeResult(key:String):void{
		getRT();
		asm.I_swap();
		asm.I_pushstring( emitter.constants.stringUtf8(key));
		asm.I_callproperty(emitter.nameFromIdent("storeResult"), 2);
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
		asm.I_getlex(emitter.qname({ns: new PublicNamespace("com.las3r.runtime"), id:"Vector"}, false))
		asm.I_swap();
		asm.I_construct(1);
	}

	/*
	* Stack:   
	*   anArray => aVector
	*/
	public function arraySliceToVector(i:int):void{
		asm.I_getlex(emitter.qname({ns: new PublicNamespace("com.las3r.runtime"), id:"Vector"}, false))
		asm.I_swap();
		asm.I_pushint(emitter.constants.int32(i));
		asm.I_callproperty(emitter.nameFromIdent("createFromArraySlice"), 2);
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
	var str:String;
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
	var num:Number;

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
	var v:Object;
	var id:int;
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
	var k:Keyword;
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
	var aVar:Var;
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
	var aVar:Var;
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
	var testExpr:Expr;
	var thenExpr:Expr;
	var elseExpr:Expr;
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
		return elseExpr.interpret();
	}

	public function emit(context:C, gen:CodeGen):void{
		var nullLabel:Object = gen.asm.newLabel();
		var falseLabel:Object = gen.asm.newLabel();
		var endLabel:Object = gen.asm.newLabel();
		try
		{
			testExpr.emit(C.EXPRESSION, gen);
			gen.asm.I_dup();
			gen.asm.I_pushnull();
			gen.asm.I_ifstricteq(nullLabel);
			gen.asm.I_pushfalse();
			gen.asm.I_ifstricteq(falseLabel);
		}
		catch(e:Error)
		{
			throw new Error("RuntimeException: " + e);
		}
		
		/* TODO: Is it necessary to coerce_a the return values of the then and else?
		Getting a verification error without the coersion, if return types are different.*/

		thenExpr.emit(context, gen);
		gen.asm.I_coerce_a();
		gen.asm.I_jump(endLabel);
		gen.asm.I_label(nullLabel);
		gen.asm.I_pop();
		gen.asm.I_label(falseLabel);
		elseExpr.emit(context, gen);
		gen.asm.I_coerce_a();
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
	var exprs:IVector;
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
		if(initProvided)
		aVar.bindRoot(init.interpret());
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

class PSTATE{
	public static var REQ:PSTATE = new PSTATE();
	public static var OPT:PSTATE = new PSTATE();
	public static var REST:PSTATE = new PSTATE();
	public static var DONE:PSTATE = new PSTATE();
}
class FnExpr implements Expr{
	var nameSym:Symbol;
	var nameLb:LocalBinding;
	var params:Vector;
	var reqParams:Vector;
	var optionalParams:Vector;
	var restParam:LocalBinding;
	var body:BodyExpr;
	var paramBindings:LocalBindingSet;
	private var _compiler:Compiler;

	public function FnExpr(c:Compiler){
		_compiler = c;
	}

	public static function parse(c:Compiler, context:C, form:ISeq):Expr{
		var f:FnExpr = new FnExpr(c);
		//arglist might be preceded by symbol naming this fn
		if(RT.second(form) is Symbol)
		{
			f.nameSym = Symbol(RT.second(form));
			form = RT.cons(c.rt.FN, RT.rest(RT.rest(form)));
		}
		f.params = Vector(RT.second(form));
		if(f.params.count() > Compiler.MAX_POSITIONAL_ARITY)
		throw new Error("Can't specify more than " + Compiler.MAX_POSITIONAL_ARITY + " params");
		f.reqParams = Vector.empty();
		f.optionalParams = Vector.empty();
		f.paramBindings = new LocalBindingSet();
		var state:PSTATE = PSTATE.REQ;
		for(var i:int = 0; i < f.params.count(); i++)
		{
			var param:Object = f.params.nth(i);
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
					f.reqParams.cons(f.paramBindings.registerLocal(c.rt.nextID(), paramSym));
					break;

					case PSTATE.OPT:
					f.optionalParams.cons(f.paramBindings.registerLocal(c.rt.nextID(), paramSym, c.analyze(context, RT.second(param))));
					break;

					case PSTATE.REST:
					f.restParam = f.paramBindings.registerLocal(c.rt.nextID(), paramSym);
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
			f.nameLb = extraBindings.registerLocal(c.rt.nextID(), f.nameSym);
		}
		var bodyForms:ISeq = ISeq(RT.rest(RT.rest(form)));
		c.pushLocalBindingSet(f.paramBindings);
		c.pushLocalBindingSet(extraBindings);
		c.pushLoopLocals(f.paramBindings);
		f.body = BodyExpr(BodyExpr.parse(c, C.RETURN, bodyForms));
		c.popLoopLocals();
		c.popLocalBindingSet();
		c.popLocalBindingSet();

		return f;
	}

	public function interpret():Object{
		throw new Error("Interpretation not implemented for FnExpr.");
		return null;
	}

	public function emit(context:C, gen:CodeGen):void{
		var formalsTypes:Array = [];
		reqParams.each(function(ea:Object):void{
				formalsTypes.push(0); // '*'
			});
		optionalParams.each(function(ea:Object):void{
				formalsTypes.push(0); // '*'
			});
		var initScopeDepth:int = gen.asm.currentScopeDepth;
		var methGen:CodeGen = gen.newMethodCodeGen(formalsTypes, false, restParam != null || nameLb != null, initScopeDepth);
		if(optionalParams.count() > 0){
			var defaults:Array = optionalParams.map(function(ea:LocalBinding, i:int, a:Array):Object{ return { val: 0, kind: 0x0c } });
			methGen.meth.setDefaults(defaults);
		}
		
		// push 'this' onto the scope stack..
		methGen.pushThisScope();

		// create a scope object for this function invocation..
		methGen.pushNewActivationScope();


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
			methGen.asm.I_getlocal(i);
			// arguments object should be on TOS
			methGen.arraySliceToVector(i - 1);
			methGen.asm.I_setslot(restSlot);
		}

		if(nameLb){
			var nameSlot:int = methGen.createActivationSlotForLocalBinding(nameLb);
			methGen.asm.I_getscopeobject(methGen.currentActivation.scopeIndex);
			methGen.asm.I_getlocal(i);
			// arguments object should be on TOS
 			methGen.asm.I_getproperty(methGen.emitter.nameFromIdent("callee"));
			methGen.asm.I_setslot(nameSlot);
		}


		var loopLabel:Object = methGen.asm.I_label(undefined);

		_compiler.pushLoopLabel(loopLabel);
		body.emit(C.RETURN, methGen);
		_compiler.popLoopLabel();

		methGen.asm.I_returnvalue();

		gen.asm.I_newfunction(methGen.meth.finalize());
		if(context == C.STATEMENT){ gen.asm.I_pop(); }
	}

}



class LetExpr implements Expr{
	var bindingInits:LocalBindingSet;
	var body:Expr;
	var isLoop:Boolean;
	private var _compiler:Compiler;

	public function LetExpr(c:Compiler, bindingInits:LocalBindingSet, body:Expr, isLoop:Boolean){
		_compiler = c;
		this.bindingInits = bindingInits;
		this.body = body;
		this.isLoop = isLoop;
	}

	public static function parse(c:Compiler, context:C, frm:Object):Expr{
		var form:ISeq = ISeq(frm);
		//(let [var val var2 val2 ...] body...)

		var isLoop:Boolean = RT.first(form).equals(c.rt.LOOP);

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

		if(isLoop){
			c.pushLoopLocals(lbs);
		}

		var bodyExpr:BodyExpr = BodyExpr(BodyExpr.parse(c, isLoop ? C.RETURN : context, body));

		if(isLoop){
			c.popLoopLocals();
		}

		c.popLocalBindingSet();

		return new LetExpr(c, lbs, bodyExpr, isLoop);
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

		var loopLabel:Object = gen.asm.I_label(undefined);

		_compiler.pushLoopLabel(loopLabel);
		body.emit(context, gen);
		_compiler.popLoopLabel();
	}

}




class InvokeExpr implements Expr{
	var fexpr:Expr;
	var args:IVector;
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

	public var bindings:IMap;
	private var _syms:IVector;
	
	public function LocalBindingSet(){
		bindings = RT.map();
		_syms = RT.vector();
	}

	public function count():int{
		return _syms.count();
	}

	public function bindingFor(sym:Symbol):LocalBinding{
		return LocalBinding(bindings.valAt(sym));
	}

	public function registerLocal(num:int, sym:Symbol, init:Expr = null):LocalBinding{
		_syms.cons(sym);
		var lb:LocalBinding = new LocalBinding(num, sym, init);
		bindings.assoc(sym, lb);
		return lb;
	}

	public function each(iterator:Function):void{
		_syms.each(function(sym:*):void{
				iterator(sym, bindings.valAt(sym));
			});
	}

	public function eachWithIndex(iterator:Function):void{
		var i:int = 0;
		_syms.each(function(sym:*):void{
				iterator(sym, bindings.valAt(sym), i);
				i += 1;
			});
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
	var b:LocalBinding;

	public function LocalBindingExpr(b:LocalBinding){
		this.b = b;
	}

	public function interpret():Object{
		throw new Error("UnsupportedOperationException: Can't interpret locals");
	}

	public function emit(context:C, gen:CodeGen):void{
		if(context != C.STATEMENT){
			gen.asm.I_getlex(gen.emitter.qname({ns: new PublicNamespace(""), id: b.runtimeName}, false));
		}
	}
}




class AssignExpr implements Expr{
	var target:AssignableExpr;
	var val:Expr;

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
	var args:IVector;

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
	var keyvals:IVector;

	public function MapExpr(keyvals:IVector){
		this.keyvals = keyvals;
	}

	public function interpret():Object{
		var m:IMap = RT.map();
		for(var i:int = 0; i < keyvals.count(); i += 2){
			var key:Object = Expr(keyvals.nth(i)).interpret();
			var val:Object = Expr(keyvals.nth(i + 1)).interpret();
			m.assoc(key, val);
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
		var keyvals:IVector = Vector.empty();
		form.each(function(key:Object, val:Object):void{
				keyvals.cons(c.analyze(context == C.INTERPRET ? context : C.EXPRESSION, key));
				keyvals.cons(c.analyze(context == C.INTERPRET ? context : C.EXPRESSION, val));
			});
		return new MapExpr(keyvals);
	}
}




class RecurExpr implements Expr{
	var args:IVector;
	var loopLocals:LocalBindingSet;
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
		var loopLabel:Object = _compiler.currentLoopLabel;
		if(loopLabel == null)
		throw new Error("IllegalStateException: No loop label found for recur.");
		this.loopLocals.eachWithIndex(function(sym:Symbol, lb:LocalBinding, i:int){
				gen.asm.I_getscopeobject(gen.currentActivation.scopeIndex);
				var arg:Expr = Expr(args.nth(i));
				arg.emit(C.EXPRESSION, gen);
				gen.asm.I_setslot(lb.slotIndex);
			});
		gen.asm.I_jump(loopLabel);
	}


	public static function parse(c:Compiler, context:C, frm:Object):Expr{
		var form:ISeq = ISeq(frm);
		var loopLocals:LocalBindingSet = c.currentLoopLocals;
		if(context != C.RETURN || loopLocals == null)
		throw new Error("UnsupportedOperationException: Can only recur from tail position. Found in context: " + context);
		if(c.inCatchFinally)
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

		if(RT.length(form) == 3 && RT.third(form) is Symbol)    //field
		{
			var sym:Symbol = Symbol(RT.third(form));

			//determine static or instance
			//static target must be symbol, either fully.qualified.Classname or Classname that has been imported
			var c:Class = maybeClass(compiler, RT.second(form), false);
			if(c != null)
			return new StaticFieldExpr(compiler, c, sym.name);
			
			var instance:Expr = compiler.analyze(context == C.INTERPRET ? context : C.EXPRESSION, RT.second(form));
			return new InstanceFieldExpr(compiler, instance, sym.name);
		}
		else // method call
		{
			var call:ISeq = ISeq(RT.third(form))
			if(!(RT.first(call) is Symbol))
			throw new Error("IllegalArgumentException: Malformed member expression");

			var sym:Symbol = Symbol(RT.first(call));

			var args:IVector = Vector.empty();
			for(var s:ISeq = RT.rest(call); s != null; s = s.rest()){
				args = args.cons(compiler.analyze(context == C.INTERPRET ? context : C.EXPRESSION, s.first()));
			}

			var c:Class = maybeClass(compiler, RT.second(form), false);
			if(c != null)
			return new StaticMethodExpr(compiler, c, sym.name, args);

			var instance:Expr = compiler.analyze(context == C.INTERPRET ? context : C.EXPRESSION, RT.second(form));
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
				if(sym.name.indexOf('.') > 0 || sym.name.charAt(0) == '[')
				c = compiler.rt.classForName(sym.name);
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
	var methName:String;
	var c:Class;
	var classId:int;
	var args:IVector;
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
	var methName:String;
	var target:Expr;
	var args:IVector;
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
	var fieldName:String;
	var c:Class;
	var classId:int;
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
	var fieldName:String;
	var target:Expr;
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
	var args:IVector;
	var target:Expr;
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
	var excExpr:Expr;

	public function ThrowExpr(excExpr:Expr){
		this.excExpr = excExpr;
	}

	override public function interpret():Object{
		throw new Error("Can't interpret a throw.");
	}

	override public function emit(context:C, gen:CodeGen):void{
		// So there's a nil on the stack after the exception is thrown,
		// required so try/catch will verify equivalent stack depths in each
		// branch.
		gen.asm.I_pushnull();
		// Then, reconcile with type of ensuing catch expr...
		gen.asm.I_coerce_a(); 

		excExpr.emit(C.EXPRESSION, gen);
		gen.asm.I_throw();
	}

	public static function parse(c:Compiler, context:C, form:Object):Expr{
		if(context == C.INTERPRET)
		return c.analyze(context, RT.list(RT.list(c.rt.FN, Vector.empty(), form)));
		return new ThrowExpr(c.analyze(C.EXPRESSION, RT.second(form)));
	}

}


class CatchClause{
	//final String className;
	var c:Class;
	var className:String;
	var lb:LocalBinding;
	var handler:Expr;
	var label:Object;
	var endLabel:Object;

	public function CatchClause(c:Class, className:String, lb:LocalBinding, handler:Expr){
		this.c = c;
		this.lb = lb;
		this.handler = handler;
		this.className = className;
	}
}


class TryExpr implements Expr{
	var tryExpr:Expr;
	var catchExprs:IVector;
	var finallyExpr:Expr;
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

			
			for(var i:int = 0; i < catchExprs.count(); i++)
			{
				var clause:CatchClause = CatchClause(catchExprs.nth(i));
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
					c.inCatchFinally = true;
					var handler:Expr = BodyExpr.parse(c, context, RT.rest(RT.rest(RT.rest(f))));
					c.inCatchFinally = false;
					c.popLocalBindingSet();
					catches = catches.cons(new CatchClause(klass, className.toString(), lb, handler));
					caught = true;
				}
				else //finally
				{
					if(fs.rest() != null)
					throw new Error("Finally clause must be last in try expression");
					
					c.inCatchFinally = true;
					finallyExpr = BodyExpr.parse(c, C.STATEMENT, RT.rest(f));
					c.inCatchFinally = false;
				}
			}
		}

		return new TryExpr(c, BodyExpr.parse(c, context, RT.seq(body)), catches, finallyExpr);
	}
}

