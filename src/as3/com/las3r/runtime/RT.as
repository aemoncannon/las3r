/**
* Copyright (c) Rich Hickey. All rights reserved.
* Copyright (c) Aemon Cannon. All rights reserved.
* The use and distribution terms for this software are covered by the
* Common Public License 1.0 (http://opensource.org/licenses/cpl.php)
* which can be found in the file CPL.TXT at the root of this distribution.
* By using this software in any fashion, you are agreeing to be bound by
* the terms of this license.
* You must not remove this notice, or any other, from this software.
*/


package com.las3r.runtime{
	
	import com.las3r.io.NaiveStringWriter;
	import com.las3r.runtime.LispNamespace;
	import com.las3r.runtime.Var;
	import com.las3r.runtime.Frame;
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;


	public class RT{
		public static var instance:RT;

		public var internedStrings:Object = {};
		public var internedSymbols:Dictionary = new Dictionary();
		public var internedKeywords:Dictionary = new Dictionary();
		public var namespaces:IMap = new Map();
		public var dvals:Frame = new Frame();

		public var vars:IMap;
		public var keywords:IMap;
		public var constants:Array;

		public var traceFunc:Function = function(str:String):void{ trace(str); };
		public var debugFunc:Function = function(str:String):void{};

		private var id:int = 1;
		private var _this:RT;

		public static var T:Boolean = true;
		public static var F:Boolean = false;

		public static var TAG_KEY:String = "tag";


		public var LAS3R_NAMESPACE:LispNamespace;
		public var LOAD_FILE:Symbol;
		public var IDENTICAL:Symbol;
		public var IN_NAMESPACE:Symbol;
		public var CURRENT_NS:Var;
		public var PRINT_READABLY:Var;

		public function get DEFAULT_IMPORTS():IMap {
			return map(
				Symbol.intern1(this, "Boolean"), Boolean,
				Symbol.intern1(this, "Class"), Class,
				Symbol.intern1(this, "Compiler"), Compiler,
				Symbol.intern1(this, "Math"), Math,
				Symbol.intern1(this, "Number"), Number,
				Symbol.intern1(this, "Object"), Object,
				Symbol.intern1(this, "String"), String,
				Symbol.intern1(this, "Error"), Error
			);
		}

		public function RT():void{
			_this = this;
			constants = [];
			keywords = RT.map();
			vars = RT.map();

			LAS3R_NAMESPACE = LispNamespace.findOrCreate(this, Symbol.intern1(this, LispNamespace.LAS3R_NAMESPACE_NAME));
			CURRENT_NS = Var.internWithRoot(LAS3R_NAMESPACE, Symbol.intern1(this, "*ns*"), LAS3R_NAMESPACE);
			PRINT_READABLY = Var.internWithRoot(LAS3R_NAMESPACE, Symbol.intern1(this, "*print-readably*"), T);

			IN_NAMESPACE = Symbol.intern1(this, "in-ns");
			Var.internWithRoot(LAS3R_NAMESPACE, IN_NAMESPACE, 
				function(nsname:Symbol):LispNamespace{
					var ns:LispNamespace = LispNamespace.findOrCreate(_this, nsname);
					CURRENT_NS.set(ns);
					return ns;
				});

			LOAD_FILE = Symbol.intern1(this, "load-file");
			Var.internWithRoot(LAS3R_NAMESPACE, LOAD_FILE,
				function(arg1:Object):Object{
					//return Compiler.loadFile(String(arg1));
					return null;
				});

			IDENTICAL = Symbol.intern1(this, "identical?");
			Var.internWithRoot(LAS3R_NAMESPACE, IDENTICAL,
				function(arg1:Object, arg2:Object):Object{
					return arg1 == arg2 ? RT.T : RT.F;
				});

		}

		public function init():void{
			loadResourceScript(RT, "boot.clj");
			loadResourceScript(RT, "proxy.clj");
			loadResourceScript(RT, "zip.clj");
			loadResourceScript(RT, "xml.clj");
			loadResourceScript(RT, "set.clj");

			Var.pushBindings(this, RT.map(
					CURRENT_NS, CURRENT_NS.get()
				));
			try{
				var USER:Symbol = Symbol.intern1(this, "user");
				var LAS3R:Symbol = Symbol.intern1(this, "las3r");
				var inNs:Var = getVar(LispNamespace.LAS3R_NAMESPACE_NAME, "in-ns");
				// var refer:Var = getVar("las3r", "refer");
				(inNs.fn())(USER);
				// refer.invoke1(LAS3R);
				loadResourceScript(RT, "user.clj");
			}
			finally
			{
				Var.popBindings(this);
			}
		}


		public function loadResourceScript(c:Class, name:String):void{
			// 			InputStream ins = c.getResourceAsStream("/" + name);
			// 			if(ins != null)
			// 			{
				// 				Compiler.load(new InputStreamReader(ins), name, name);
				// 				ins.close();
				// 			}
		}

		public function currentNS():LispNamespace{
			return LispNamespace(CURRENT_NS.get());
		}

		public function classForName(name:String):Class{
			return (getDefinitionByName(name) as Class);
		}

		public function traceOut(str:String):void{
			traceFunc(str);
		}

		public static function boundedLength(list:ISeq, limit:int):int{
			var i:int = 0;
			for(var c:ISeq = list; c != null && i <= limit; c = c.rest()){
				i++;
			}
			return i;
		}

		public static function count(o:Object):int{
			if(o == null)
			return 0;
			else if(o is ASeq)
			return (ASeq(o)).count();
			else if(o is String)
			return (String(o)).length;
			else if(o is Array)
			return o.length;
			throw new Error("UnsupportedOperationException: count not supported on this type.");
		}

		public static function length(list:ISeq):int{
			var i:int = 0;
			for(var c:ISeq = list; c != null; c = c.rest()){
				i++;
			}
			return i;
		}


		public function nextID():int{
			this.id += 1;
			return this.id;
		}

		public static function list():ISeq{
			return null;
		}

		public static function list1(arg1:Object):ISeq{
			return new List(arg1);
		}

		public static function list2(arg1:Object, arg2:Object):ISeq{
			return listStar2(arg1, arg2, null);
		}

		public static function list3(arg1:Object, arg2:Object, arg3:Object):ISeq{
			return listStar3(arg1, arg2, arg3, null);
		}

		public static function list4(arg1:Object, arg2:Object, arg3:Object, arg4:Object):ISeq{
			return listStar4(arg1, arg2, arg3, arg4, null);
		}

		public static function list5(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object):ISeq{
			return listStar5(arg1, arg2, arg3, arg4, arg5, null);
		}

		public static function listStar1(arg1:Object, rest:ISeq):ISeq{
			return ISeq(cons(arg1, rest));
		}

		public static function listStar2(arg1:Object, arg2:Object, rest:ISeq):ISeq{
			return ISeq(cons(arg1, cons(arg2, rest)));
		}

		public static function listStar3(arg1:Object, arg2:Object, arg3:Object, rest:ISeq):ISeq{
			return ISeq(cons(arg1, cons(arg2, cons(arg3, rest))));
		}

		public static function listStar4(arg1:Object, arg2:Object, arg3:Object, arg4:Object, rest:ISeq):ISeq{
			return ISeq(cons(arg1, cons(arg2, cons(arg3, cons(arg4, rest)))));
		}

		public static function listStar5(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, rest:ISeq):ISeq{
			return ISeq(cons(arg1, cons(arg2, cons(arg3, cons(arg4, cons(arg5, rest))))));
		}

		public static function conj(coll:Object, x:Object):ISeq{
			if(coll == null){
				return new List(x);
			}
			else if(coll is IVector){
				return coll.cons(x);
			}
			else if(coll is ISeq){
				return coll.cons(x);
			}
			else
			throw new ("UnsupportedOperationException: conj not supported on this object: " + coll);
		}

		public static function get(coll:Object, key:Object, notFound:Object = null):Object{
			if(coll == null)
			return notFound;
			else if(coll is IMap)
			{
				var m:IMap = IMap(coll);
				if(m.containsKey(key))
				return m.valAt(key);
				return notFound;
			}
			else if(key is Number && (coll is String || coll is Array || coll is IVector))
			{
				var n:int = int(key);
				return n >= 0 && n < count(coll) ? nth(coll, n) : notFound;
			}
			return notFound;
		}


		public static function nth(coll:Object, n:int):Object{
			if(coll == null)
			return null;
			else if(coll is IVector)
			return IVector(coll).nth(n);
			else if(coll is String)
			return String(coll).charAt(n);
			else if(coll is Array)
			return coll[n];
			else if(coll is ISeq)
			{
				var seq:ISeq = ISeq(coll);
				for(var i:int = 0; i <= n && seq != null; ++i, seq = seq.rest())
				{
					if(i == n)
					return seq.first();
				}
				throw new Error("IndexOutOfBoundsException");
			}
			else
			throw new ("UnsupportedOperationException: nth not supported on this object: " + coll);
		}


		public static function cons(x:Object, coll:Object):ISeq{
			var y:ISeq = seq(coll);
			if(y == null)
			return new List(x);
			return y.cons(x);
		}

		public static function first(x:Object):Object{
			var seq:ISeq = seq(x);
			if(seq == null)
			return null;
			return seq.first();
		}

		public static function second(x:Object):Object{
			return first(rest(x));
		}

		public static function third(x:Object):Object{
			return first(rest(rest(x)));
		}

		public static function fourth(x:Object):Object{
			return first(rest(rest(rest(x))));
		}

		public static function rest(x:Object):ISeq{
			var seq:ISeq = seq(x);
			if(seq == null)
			return null;
			return seq.rest();
		}

		public static function rrest(x:Object):ISeq{
			return rest(rest(x));
		}

		public static function seq(coll:Object):ISeq{
			if(coll == null){
				return null;
			}
			else if(coll is ISeq){
				return (ISeq(coll)).seq();
			}
			else if(coll is IVector){
				return IVector(coll).seq();
			}
			else if(coll is IMap){
				return IMap(coll).seq();
			}
			else if(coll is String){
				return new StringSeq(String(coll), 0);
			}
			else{
				throw new Error("IllegalArgumentException: Don't know how to create ISeq from " + coll);
			}
		}

		public static function assoc(map:IMap, key:Object, val:Object):IMap{
			map.assoc(key, val);
			return map;
		}

		public static function map(...init:Array):IMap{
			return Map.createFromArray(init);
		}

		public static function vector(...init:Array):IVector{
			return new Vector(init);
		}

		public function getVar(ns:String, name:String):Var{
			return Var.internNS(LispNamespace.findOrCreate(this, Symbol.intern2(this, null, ns)), Symbol.intern2(this, null, name));
		}

		public static function printToString(x:Object):String {
			var w:NaiveStringWriter = new NaiveStringWriter();
			print(x, w);
			return w.toString();
		}

		public static function print(x:Object, w:NaiveStringWriter):void {
			//TODO - make extensible
			var readably:Boolean = true;
			if(x == null)
			w.write("nil");
			else if(x is ISeq || x is IList)
			{
				w.write('(');
					printInnerSeq(seq(x), w);
					w.write(')');
			}
			else if(x is String)
			{
				var s:String = String(x);
				if(!readably)
				w.write(s);
				else
				{
					w.write('"');
					//w.write(x.toString());
					for(var i:int = 0; i < s.length; i++)
					{
						var c:String = s.charAt(i);
						switch(c)
						{
							case '\n':
							w.write("\\n");
							break;
							case '\t':
							w.write("\\t");
							break;
							case '\r':
							w.write("\\r");
							break;
							case '"':
							w.write("\\\"");
							break;
							case '\\':
							w.write("\\\\");
							break;
							case '\f':
							w.write("\\f");
							break;
							case '\b':
							w.write("\\b");
							break;
							default:
							w.write(c);
						}
					}
					w.write('"');
				}
			}
			else if(x is IMap)
			{
				w.write('{');
					for(var sq:ISeq = seq(x); sq != null; sq = sq.rest())
					{
						var v:IVector = IVector(sq.first());
						print(v.nth(0), w);
						w.write(' ');
						print(v.nth(1), w);
						if(sq.rest() != null)
						w.write(", ");
					}
					w.write('}');
			}
			else if(x is IVector)
			{
				var a:IVector = IVector(x);
				w.write('[');
					for(var i:int = 0; i < a.count(); i++)
					{
						print(a.nth(i), w);
						if(i < a.count() - 1)
						w.write(' ');
					}
					w.write(']');
			}
			else w.write(x.toString());
		}


		private static function printInnerSeq(x:ISeq, w:NaiveStringWriter):void{
			for(var sq:ISeq = x; sq != null; sq = sq.rest())
			{
				print(sq.first(), w);
				if(sq.rest() != null)
				w.write(' ');
			}
		}


	}
}