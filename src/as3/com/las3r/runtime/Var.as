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

	import com.las3r.runtime.RT;

	public class Var extends Obj{

		public static var UNBOUND_VAL:Object = {};

		public var root:Object;
		public var count:int;
		public var sym:Symbol;
		public var ns:LispNamespace;
		private var _rt:RT;

		public function Var(rt:RT, ns:LispNamespace, sym:Symbol, root:Object = null){
			_rt = rt;
			this.ns = ns;
			this.sym = sym;
			this.count = 0;
			this.root = root === null ? UNBOUND_VAL : root;
			setMeta(RT.map());
		}


		public function toString():String {
			if(ns != null)
			return "#'" + ns.getName() + "/" + sym;
			return "#<Var: " + (sym != null ? sym.toString() : "--unnamed--") + ">";
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
		}

		public function unbindRoot():void{
			this.root = UNBOUND_VAL;
		}

		public function commuteRoot(fn:Function):void{
			this.root = fn(root);
		}

		public static function pushBindings(rt:RT, bindings:IMap):void{
			var f:Frame = rt.dvals;
			var newMap:IMap = new Map();

			bindings.each(function(v:Var, val:*):void{
					v.count += 1;
					newMap.assoc(v, new Box(val));
				});
			rt.dvals = new Frame(newMap, f);
		}

		public static function popBindings(rt:RT):void{
			var f:Frame = rt.dvals;
			if(f.prev == null)
			throw new Error("IllegalStateException: Pop without matching push");

			f.bindings.each(function(v:Var, val:Box):void{
					v.count -= 1;
				});

			rt.dvals = f.prev;
		}

		public static function releaseBindings(rt:RT):void{
			var f:Frame = rt.dvals;
			if(f.prev == null)
			throw new Error("IllegalStateException: Release without full unwind");

			f.bindings.each(function(v:Var, val:Box):void{
					v.count -= 1;
				});
			rt.dvals = null;
		}

		public function getBinding():Box{
			if(count > 0)
			{
				for(var f:Frame = _rt.dvals; f != null; f = f.prev){
					var val:Object = f.bindings.valAt(this);
					if(val != null){
						return Box(val);
					}
				}
			}
			return null;
		}

		public function fn():Function{
			return get() as Function;
		}

		public function apply(args:Vector):Object{
			var f:Function = fn();
			return f.apply(null, args);
		}

		public function setMeta(m:IMap):void{
			//ensure these basis keys
			_meta = m.assoc(_rt.NAME_KEY, sym).assoc(_rt.NS_KEY, ns);
		}

		public function setMacro():void{
			_meta = _meta.assoc(_rt.MACRO_KEY, RT.T);
		}

		public function isMacro():Boolean{
			return (_meta.valAt(_rt.MACRO_KEY) != null);
		}

		public function isPublic():Boolean{
			return (_meta.valAt(_rt.PRIVATE_KEY) == null);
		}


	}
}
