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

	import com.las3r.util.Util;
	import com.las3r.runtime.RT;

	public class Var extends Obj implements IFn{

		public static var UNBOUND_VAL:Object = {};

		public var root:Object;
		public var count:int;
		public var sym:Symbol;
		public var ns:LispNamespace;
		private var _rt:RT;
		private var hash:int;

		public function Var(rt:RT, ns:LispNamespace, sym:Symbol, root:Object = null){
			_rt = rt;
			this.ns = ns;
			this.sym = sym;
			this.count = 0;
			this.root = root === null ? UNBOUND_VAL : root;
			this.hash = Util.stringHash(toString());
			setMeta(RT.map());
		}

		public function toString():String {
			if(ns != null){
				return "#'" + ns.getName() + "/" + sym;
			}
			else if(sym){
				return "#<Var " + _rt.nextID() + ": " + sym + ">";
			}
			else{
				return "#<Var: "  + _rt.nextID() + "--unnamed-- >";
			}
		}

		override public function hashCode():int{
			return this.hash;
		}

		public static function create(rt):Var{
			return new Var(rt, null, null);
		}

		public static function find(rt:RT, nsQualifiedSym:Symbol):Var{
			if(nsQualifiedSym.getNamespace() == null)
			throw new Error("IllegalArgumentException: Symbol must be namespace-qualified");
			var ns:LispNamespace = LispNamespace.find(rt, Symbol.intern1(rt, nsQualifiedSym.getNamespace()));
			if(ns == null)
			throw new Error("IllegalArgumentException: No such namespace: " + nsQualifiedSym.getNamespace());
			return ns.findInternedVar(Symbol.intern1(rt, nsQualifiedSym.getName()));
		}

		public static function internWithRoot(ns:LispNamespace, sym:Symbol, root:Object, replaceRoot:Boolean = true):Var{
			var dvout:Var = ns.intern(sym);
			if(!dvout.hasRoot() || replaceRoot){
				dvout.bindRoot(root);
			}
			return dvout;
		}

		public static function internNS(ns:LispNamespace, sym:Symbol):Var{
			return ns.intern(sym);
		}

		public static function internNSByName(rt:RT, nsName:Symbol, sym:Symbol):Var{
			var ns:LispNamespace = LispNamespace.findOrCreate(rt, nsName);
			return internNS(ns, sym);
		}

		public function isBound():Boolean{
			return hasRoot() || (count > 0 && _rt.dvals.bindings.containsKey(this));
		}

		public function get():Object{
			var b:Box = getBinding();
			if(b != null)
			return b.val;
			if(hasRoot())
			return root;
			throw new Error("IllegalStateException: " + "Var is unbound: " + sym);
		}

		public function alter(fn:Function, args:ISeq):Object{
			set(fn.apply(null, RT.cons(get(), args)));
			return this;
		}

		public function alterRoot(fn:Function, args:ISeq):Object {
			var newRoot:Object = fn.apply(null, RT.seqToArray(RT.cons(root, args)));
			this.root = newRoot;
			return newRoot;
		}

		public function set(val:Object):Object {
			var b:Box = getBinding();
			if(b != null)
			return (b.val = val);
			throw new Error("IllegalStateExceptionString: Can't change/establish root binding of: " + sym + " with set.");
		}

		public function getRoot():Object{
			return root;
		}

		public function hasRoot():Boolean{
			return root != UNBOUND_VAL;
		}

		//binding root always clears macro flag
		public function bindRoot(root:Object):void{
			this.root = root;
			_meta = _meta.assoc(_rt.MACRO_KEY, RT.F);
		}

		public function unbindRoot():void{
			this.root = UNBOUND_VAL;
		}

		public function commuteRoot(fn:Function):void{
			this.root = fn(root);
		}

		public static function pushBindings(rt:RT, bindings:IMap):void{
			var f:Frame = rt.dvals;
			var bmap:IMap = f.bindings;
			for(var bs:ISeq = bindings.seq(); bs != null; bs = bs.rest())
			{
				var e:MapEntry = MapEntry(bs.first());
				var v:Var = Var(e.key);
				v.count += 1;
				bmap = bmap.assoc(v, new Box(e.value));
			}
			rt.dvals = new Frame(bindings, bmap, f);
		}

		public static function popBindings(rt:RT):void{
			var f:Frame = rt.dvals;
			if(f.prev == null)
			throw new Error("IllegalStateException: Pop without matching push");
			for(var bs:ISeq = RT.keys(f.frameBindings); bs != null; bs = bs.rest())
			{
				var v:Var = Var(bs.first());
				v.count -= 1;
			}
			rt.dvals = f.prev;
		}

		public static function releaseBindings(rt:RT):void{
			var f:Frame = rt.dvals;
			if(f.prev == null)
			throw new Error("IllegalStateException: Release without full unwind");
			for(var bs:ISeq = RT.keys(f.bindings); bs != null; bs = bs.rest())
			{
				var v:Var = Var(bs.first());
				v.count -= 1;
			}
			rt.dvals = null;
		}

		public function getBinding():Box{
			if(count > 0)
			{
				var e:MapEntry = _rt.dvals.bindings.entryAt(this);
				if(e != null){
					return Box(e.value);
				}
			}
			return null;
		}

		public function fn():Function{
			return get() as Function;
		}

		public function call():Object{
			return invoke0();
		}

		public function setMeta(m:IMap):void{
			//ensure these basis keys
			_meta = m.assoc(_rt.NAME_KEY, sym).assoc(_rt.NS_KEY, ns);
		}

		public function setMacro():void{
			_meta = _meta.assoc(_rt.MACRO_KEY, RT.T);
		}

		public function isMacro():Boolean{
			return (_meta.valAt(_rt.MACRO_KEY) === RT.T);
		}

		public function isPublic():Boolean{
			return (_meta.valAt(_rt.PRIVATE_KEY) == null);
		}

		public function invoke0() :Object{
			return fn()();
		}

		public function invoke1(arg1:Object) :Object{
			return fn()(arg1);
		}

		public function invoke2(arg1:Object, arg2:Object) :Object{
			return fn()(arg1, arg2);
		}

		public function invoke3(arg1:Object, arg2:Object, arg3:Object) :Object{
			return fn()(arg1, arg2, arg3);
		}

		public function invoke4(arg1:Object, arg2:Object, arg3:Object, arg4:Object) :Object{
			return fn()(arg1, arg2, arg3, arg4);
		}

		public function invoke5(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object) :Object{
			return fn()(arg1, arg2, arg3, arg4, arg5);
		}

		public function invoke6(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object) :Object{
			return fn()(arg1, arg2, arg3, arg4, arg5, arg6);
		}

		public function invoke7(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object)
		:Object{
			return fn()(arg1, arg2, arg3, arg4, arg5, arg6, arg7);
		}

		public function invoke8(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object) :Object{
			return fn()(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8);
		}

		public function invoke9(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object, arg9:Object) :Object{
			return fn()(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9);
		}

		public function invoke10(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object, arg9:Object, arg10:Object) :Object{
			return fn()(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10);
		}

		public function invoke11(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object, arg9:Object, arg10:Object, arg11:Object) :Object{
			return fn()(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11);
		}

		public function invoke12(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object, arg9:Object, arg10:Object, arg11:Object, arg12:Object) :Object{
			return fn()(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12);
		}

		public function invoke13(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object, arg9:Object, arg10:Object, arg11:Object, arg12:Object, arg13:Object)
		:Object{
			return fn()(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13);
		}

		public function invoke14(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object, arg9:Object, arg10:Object, arg11:Object, arg12:Object, arg13:Object, arg14:Object)
		:Object{
			return fn()(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14);
		}

		public function invoke15(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object, arg9:Object, arg10:Object, arg11:Object, arg12:Object, arg13:Object, arg14:Object,
            arg15:Object) :Object{
			return fn()(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15);
		}

		public function invoke16(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object, arg9:Object, arg10:Object, arg11:Object, arg12:Object, arg13:Object, arg14:Object,
            arg15:Object, arg16:Object) :Object{
			return fn()(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15,
	            arg16);
		}

		public function invoke17(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object, arg9:Object, arg10:Object, arg11:Object, arg12:Object, arg13:Object, arg14:Object,
            arg15:Object, arg16:Object, arg17:Object) :Object{
			return fn()(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15,
	            arg16, arg17);
		}

		public function invoke18(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object, arg9:Object, arg10:Object, arg11:Object, arg12:Object, arg13:Object, arg14:Object,
            arg15:Object, arg16:Object, arg17:Object, arg18:Object) :Object{
			return fn()(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15,
	            arg16, arg17, arg18);
		}

		public function invoke19(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object, arg9:Object, arg10:Object, arg11:Object, arg12:Object, arg13:Object, arg14:Object,
            arg15:Object, arg16:Object, arg17:Object, arg18:Object, arg19:Object) :Object{
			return fn()(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15,
	            arg16, arg17, arg18, arg19);
		}

		public function invoke20(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object, arg9:Object, arg10:Object, arg11:Object, arg12:Object, arg13:Object, arg14:Object,
            arg15:Object, arg16:Object, arg17:Object, arg18:Object, arg19:Object, arg20:Object)
		:Object{
			return fn()(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15,
	            arg16, arg17, arg18, arg19, arg20);
		}

		public function applyTo(arglist:ISeq):Object{
			var f:Object = get();
			if(f is Function){
				return (f as Function).apply(null, RT.seqToArray(arglist));
			}
			else if(f is IFn){
				return AFn.applyToHelper(this, arglist);
			}
			throw new Error("Cannot applyTo non-Function/IFn.")
			return null;
		}

		public function applyAsFunctionToArray(arglist:Array):Object{
			var f:Function = fn();
			return f.apply(null, arglist);
		}


	}
}
