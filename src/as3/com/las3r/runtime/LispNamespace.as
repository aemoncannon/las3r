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

	import flash.utils.Dictionary;

	public class LispNamespace implements IHashable{
		public var name:Symbol;
		private var _mappings:IMap = new Map();
		private var _aliases:IMap = new Map();
		private var _rt:RT;

		public static var LAS3R_NAMESPACE_NAME:String = "las3r";

		public function equals(val:Object):Boolean{
			return val == this;
		}

		public function toString():String {
			return "#<LispNamespace: " + name + ">";
		}

		public function hashCode():*{
			return toString();
		}

		function LispNamespace(rt:RT, name:Symbol){
			_rt = rt;
			this.name = name;
			rt.DEFAULT_IMPORTS.each(function(key:Object, val:Object):void{
					_mappings = _mappings.assoc(key, val);
				});
		}


		public function getName():Symbol{
			return name;
		}


		public function getMappings():IMap{
			return _mappings;
		}

		public function intern(sym:Symbol):Var{
			if(sym.getNamespace() != null)
			{
				throw new Error("IllegalArgumentException: Can't intern namespace-qualified symbol");
			}
			var o:Object = _mappings.valAt(sym);
			if(o is Var && (Var(o).ns == this)) {
				return Var(o);
			}
			else if(o == null){
				var v:Var = new Var(_rt, this, sym);
				_mappings = _mappings.assoc(sym, v);
				return v;
			}
			else{
				throw new Error("IllegalStateException: " + sym + " already refers to: " + o + " in namespace: " + name);
			}
		}


		public function reference(sym:Symbol, val:Object):Object{
			if(sym.getNamespace() != null)
			{
				throw new Error("IllegalArgumentException: Can't intern namespace-qualified symbol");
			}
			var o:Object = _mappings.valAt(sym);
			if(o == val) {
				return o;
			}
			else if(o == null){
				_mappings = _mappings.assoc(sym, val);
				return val;
			}
			else{
				throw new Error("IllegalStateException: " + sym + " already refers to: " + o + " in namespace: " + name);
			}
		}


		public function unmap(sym:Symbol):void{
			if(sym.getNamespace() != null)
			{
				throw new Error("IllegalArgumentException: Can't unintern namespace-qualified symbol");
			}
			_mappings = _mappings.without(sym);
		}


		public function importClass(sym:Symbol, c:Class):Class{
			return Class(reference(sym, c));
		}


		public function refer(sym:Symbol, v:Var):Var{
			return Var(reference(sym, v));
		}

		public static function all(rt:RT):ISeq{
			return RT.seq(rt.namespaces);
		}

		public static function findOrCreate(rt:RT, name:Symbol):LispNamespace {
			var ns:LispNamespace = LispNamespace(rt.namespaces.valAt(name));
			if(ns != null)
			return ns;

			var newns:LispNamespace = new LispNamespace(rt, name);
			rt.namespaces = rt.namespaces.assoc(name, newns);
			return newns;
		}


		public static function remove(rt:RT, name:Symbol):LispNamespace{
			if(name.getName() == LAS3R_NAMESPACE_NAME)
			throw new Error("IllegalArgumentException: Cannot remove las3r namespace");
			var ns:LispNamespace  = LispNamespace(rt.namespaces.valAt(name));
			rt.namespaces = rt.namespaces.without(name);
			return ns;
		}


		public static function find(rt:RT, name:Symbol):LispNamespace {
			return LispNamespace(rt.namespaces.valAt(name));
		}


		public function getMapping(name:Symbol):Object{
			return _mappings.valAt(name);
		}


		public function findInternedVar(symbol:Symbol){
			var o:Object = _mappings.valAt(symbol);
			if(o != null && o is Var && (Var(o)).ns == this)
			return Var(o);
			return null;
		}

		public function getAliases():IMap{
			return _aliases;
		}

		public function lookupAlias(alias:Symbol):LispNamespace{
			return LispNamespace(_aliases.valAt(alias));
		}

		public function addAlias(alias:Symbol, ns:LispNamespace):void{
			if (alias == null || ns == null)
			throw new Error("NullPointerException: Expecting Symbol + Namespace");
			_aliases = _aliases.assoc(alias, ns);
			// you can rebind an alias, but only to the initially-aliased namespace.
			if(!_aliases.valAt(alias).equals(ns))
			throw new Error("IllegalStateException: Alias " + alias + " already exists in namespace " + name + ", aliasing " + _aliases.valAt(alias));
		}

		public function removeAlias(alias:Symbol):void{
			_aliases = _aliases.without(alias);
		}


	}
}