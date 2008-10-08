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
	import com.las3r.jdk.io.*;
	import com.las3r.runtime.LispNamespace;
	import com.las3r.runtime.Var;
	import com.las3r.runtime.Frame;
	import flash.events.Event;
	import flash.display.Stage;
	import flash.utils.Dictionary;
	import flash.utils.ByteArray;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;


	public class RT{

		[Embed(source="../../../../lsr/boot.lsr", mimeType="application/octet-stream")]
		protected const BootLsr:Class;
		public var BOOT_LSR:String = (ByteArray(new BootLsr).toString());

		public static var instances:Array = [];

		public var instanceId:int = -1;
		public var internedStrings:Object = {};
		public var internedSymbols:Dictionary = new Dictionary();
		public var internedKeywords:Dictionary = new Dictionary();
		public var namespaces:IMap = new Map();
		public var specials:Vector;
		public var dvals:Frame = new Frame();

		public var vars:IMap;
		public var keywords:IMap;
		public var constants:Array;

		public var traceFunc:Function = function(str:String):void{ trace(str); };
		public var debugFunc:Function = function(str:String):void{};

		private var id:int = 1;
		private var _this:RT;
		private var _resultsDict:Dictionary = new Dictionary();

		private var _compiler:Compiler;
		public function get compiler():Compiler { return _compiler }

		private var _lispReader:LispReader;
		public function get lispReader():LispReader { return _lispReader }

		private var _stage:Stage;
		public function get stage():Stage { return _stage }


		public static var T:Boolean = true;
		public static var F:Boolean = false;


		public var LAS3R_NAMESPACE:LispNamespace;
		public var LOAD_FILE:Symbol;
		public var IDENTICAL:Symbol;
		public var IN_NAMESPACE:Symbol;
		public var CURRENT_NS:Var;
		public var RUNTIME:Var;
		public var STAGE:Var;
		public var SAVE_BYTECODES:Var;
		public var PRINT_READABLY:Var;
		public var TAG_KEY:Keyword;
		public var MACRO_KEY:Keyword;
		public var BYTECODES_KEY:Keyword;
		public var PRIVATE_KEY:Keyword;
		public var NAME_KEY:Keyword;
		public var NS_KEY:Keyword;


		public var CONCAT:Symbol;
		public var APPLY:Symbol;
		public var WITH_META:Symbol;
		public var META:Symbol;
		public var SLASH:Symbol;
		public var DEREF:Symbol;


		// Special forms..
		public var DEF:Symbol;
		public var LOOP:Symbol;
		public var RECUR:Symbol;
		public var IF:Symbol;
		public var LET:Symbol;
		public var DO:Symbol;
		public var FN:Symbol;
		public var QUOTE:Symbol;
		public var THE_VAR:Symbol;
		public var DOT:Symbol;
		public var ASSIGN:Symbol;
		public var TRY:Symbol;
		public var CATCH:Symbol;
		public var FINALLY:Symbol;
		public var THROW:Symbol;
		public var MONITOR_ENTER:Symbol;
		public var MONITOR_EXIT:Symbol;
		public var NEW:Symbol;
		public var LIST:Symbol;
		public var HASHMAP:Symbol;
		public var VECTOR:Symbol;
		public var _AMP_:Symbol;
		public var ISEQ:Symbol;


		public function get DEFAULT_IMPORTS():IMap {
			return map(
				sym1("Boolean"), Boolean,
				sym1("Class"), Class,
				sym1("Compiler"), Compiler,
				sym1("Math"), Math,
				sym1("Number"), Number,
				sym1("Object"), Object,
				sym1("String"), String,
				sym1("Error"), Error
			);
		}

		public function RT(stage:Stage = null):void{
			_this = this;
			_stage = stage;
			var forceImport:Array = [Numbers, LazyCons];
			instances.push(this);
			instanceId = instances.length - 1;
			constants = [];
			keywords = RT.map();
			vars = RT.map();

			TAG_KEY = key1(sym1("tag"));
			MACRO_KEY = key1(sym1("macro"));
			BYTECODES_KEY = key1(sym1("bytecodes"));
			PRIVATE_KEY = key1(sym1("private"));
			NS_KEY = key1(sym1("ns"));
			NAME_KEY = key1(sym1("name"));

			LAS3R_NAMESPACE = LispNamespace.findOrCreate(this, sym1(LispNamespace.LAS3R_NAMESPACE_NAME));
			CURRENT_NS = Var.internWithRoot(LAS3R_NAMESPACE, sym1("*ns*"), LAS3R_NAMESPACE);
			RUNTIME = Var.internWithRoot(LAS3R_NAMESPACE, sym1("*runtime*"), this);
			STAGE = Var.internWithRoot(LAS3R_NAMESPACE, sym1("*stage*"), _stage);
			PRINT_READABLY = Var.internWithRoot(LAS3R_NAMESPACE, sym1("*print-readably*"), T);
			SAVE_BYTECODES = Var.internWithRoot(LAS3R_NAMESPACE, sym1("*save-bytecodes*"), F);

			IN_NAMESPACE = sym1("in-ns");
			Var.internWithRoot(LAS3R_NAMESPACE, IN_NAMESPACE, 
				function(nsname:Symbol):LispNamespace{
					var ns:LispNamespace = LispNamespace.findOrCreate(_this, nsname);
					CURRENT_NS.set(ns);
					return ns;
				});

			LOAD_FILE = sym1("load-file");
			Var.internWithRoot(LAS3R_NAMESPACE, LOAD_FILE,
				function(arg1:Object):Object{
					//return Compiler.loadFile(String(arg1));
					return null;
				});

			IDENTICAL = sym1("identical?");
			Var.internWithRoot(LAS3R_NAMESPACE, IDENTICAL,
				function(arg1:Object, arg2:Object):Object{
					return arg1 == arg2 ? RT.T : RT.F;
				});

			CONCAT = sym1("concat");
			Var.internWithRoot(LAS3R_NAMESPACE, CONCAT,
				function(...args:Array):Object{
					return RT.concat.apply(null, args);
				});

			APPLY = sym1("apply*");
			Var.internWithRoot(LAS3R_NAMESPACE, APPLY,
				function(func:Function, args:ISeq):Object{
					var ar:Array = [];
					for(var c:ISeq = args; c != null; c = c.rest()){ ar.push(c.first()); }
					return func.apply(null, ar);
				});

			VECTOR = sym1("vector");
			Var.internWithRoot(LAS3R_NAMESPACE, VECTOR,
				function(...args:Array):Object{
					return Vector.createFromArray(args);
				});

			HASHMAP = sym1("hash-map");
			Var.internWithRoot(LAS3R_NAMESPACE, HASHMAP,
				function(...args:Array):Object{
					return Map.createFromArray(args);
				});

			LIST = sym1("list");
			Var.internWithRoot(LAS3R_NAMESPACE, LIST,
				function(...args:Array):Object{
					return List.createFromArray(args);
				});


			WITH_META = sym2(LispNamespace.LAS3R_NAMESPACE_NAME, "with-meta");
			META = sym2(LispNamespace.LAS3R_NAMESPACE_NAME, "meta");
			DEREF = sym2(LispNamespace.LAS3R_NAMESPACE_NAME, "deref");
			SLASH = sym2(null, "/"); // Don't want namespace.


			DEF = sym1("def");
			LOOP = sym1("loop*");
			RECUR = sym1("recur");
			IF = sym1("if");
			LET = sym1("let*");
			DO = sym1("do");
			FN = sym1("fn*");
			QUOTE = sym1("quote");
			THE_VAR = sym1("var");
			DOT = sym1(".");
			ASSIGN = sym1("set!");
			TRY = sym1("try");
			CATCH = sym1("catch");
			FINALLY = sym1("finally");
			THROW = sym1("throw");
			MONITOR_ENTER = sym1("monitor-enter");
			MONITOR_EXIT = sym1("monitor-exit");
			NEW = sym1("new");
			HASHMAP = sym2(LispNamespace.LAS3R_NAMESPACE_NAME, "hash-map");
			VECTOR = sym2(LispNamespace.LAS3R_NAMESPACE_NAME, "vector");
			_AMP_ = sym1("&");
			ISEQ = sym1("com.las3r.runtime.ISeq");

			specials = Vector(RT.vector(
					DEF,
					LOOP,
					RECUR,
					IF,
					LET,
					DO,
					FN,
					QUOTE,
					THE_VAR,
					DOT,
					ASSIGN,
					TRY,
					CATCH, 
					FINALLY, 
					THROW,
					NEW,
					_AMP_
				));

			_compiler = new Compiler(this);
			_lispReader = new LispReader(this);
		}

		public function isSpecial(sym:Object):Boolean{
			return specials.includes(sym);
		}

		public function sym1(name:String):Symbol{
			return Symbol.intern1(this, name);
		}

		public function sym2(ns:String, name:String):Symbol{
			return Symbol.intern2(this, ns, name);
		}

		public function key1(name:Symbol):Keyword{
			return Keyword.intern1(this, name);
		}

		public function resolveSymbol(sym:Symbol):Symbol{
			//already qualified or classname?
			if(sym.name.indexOf('.') > 0){
				return sym;
			}
			if(sym.ns != null)
			{
				var ns:LispNamespace = namespaceFor(sym);
				if(ns == null || ns.name.name == sym.ns)
				return sym;
				return sym2(ns.name.name, sym.name);
			}
			var o:Object = currentNS().getMapping(sym);
			if(o == null){
				return sym2(currentNS().name.name, sym.name);
			}
			else if(o is Class){
				return sym2(null, getQualifiedClassName(Class(o)));
			}
			else if(o is Var)
			{
				var v:Var = Var(o);
				return sym2(v.ns.name.name, v.sym.name);
			}
			return null;

		}

		private function namespaceFor(sym:Symbol):LispNamespace{
			//note, presumes non-nil sym.ns
			// first check against currentNS' aliases...
			var nsSym:Symbol = sym1(sym.ns);
			var ns:LispNamespace = LispNamespace.find(this, nsSym);
			return ns;
		}

		public function resolve(sym:Symbol):Object{
			return resolveIn(currentNS(), sym);
		}


		public function resolveIn(n:LispNamespace, sym:Symbol):Object{
			//note - ns-qualified vars must already exist
			if(sym.ns != null)
			{
				var ns:LispNamespace = LispNamespace.find(this, sym1(sym.ns));
				if(ns == null){
					throw new Error("No such namespace: " + sym.ns);
				}
				var v:Var = ns.findInternedVar(sym1(sym.name));
				if(v == null){
					throw new Error("No such var: " + sym);
				}
				else if(v.ns != currentNS() && !v.isPublic()){
					throw new Error("IllegalStateException: var: " + sym + " is not public");
				}
				return v;
			}
			else if(sym.name.indexOf('.') > 0 || sym.name.charAt(0) == '[')
			{
				return classForName(sym.name);
			}
			else
			{
				var o:Object = n.getMapping(sym);
				if(o == null){
					throw new Error("Unable to resolve symbol: " + sym + " in this context");
				}
				return o;
			}
		}




		public function loadStdLib(onComplete:Function = null):void{
			_compiler.load(new PushbackReader(new StringReader(BOOT_LSR)), onComplete || function(val:*):void{});
		}


		public function evalStr(src:String, _onComplete:Function = null):void{
			var onComplete:Function = _onComplete || function(val:*):void{};
			_compiler.load(new PushbackReader(new StringReader(src)), onComplete);
		}

		
		/**
		* As code is loaded asynchronously, we provide a facility for the loaded code to invoke a callback with its result.
		* @param val 
		* @param key 
		* @return 
		*/		
		public function callbackWithResult(val:*, key:String):void{
			var f:Function = _resultsDict[key];
			if((f == null) || !(f is Function)){
				throw new Error("IllegalStateException: Compiled form tried to callback to non-existant callback.")
			}
			else{
				f(val);
			}
		}

		public function createResultCallback(callback:Function):String{
			var key:String = "result_callback_" + nextID();
			_resultsDict[key] = callback;
			return key;
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

		public static function list(...rest:Array):ISeq{
			return List.createFromArray(rest);
		}

		public static function isInstance(c:Class, x:Object):Boolean{
			return x is c;
		}

		public static function cast(c:Class, x:Object):*{
			return c(x);
		}

		public static function conj(coll:Object, x:Object):Object{
			if(coll == null){
				return new List(x);
			}
			else if(coll is IVector || coll is ISeq || coll is IMap){
				return coll.cons(x);
			}
			else{
				throw new Error("UnsupportedOperationException: conj not supported on this object: " + coll);
			}
		}

		public static function get(coll:Object, key:Object, notFound:Object = null):Object{
			if(coll == null){
				return notFound;
			}
			else if(coll is IMap)
			{
				var m:IMap = IMap(coll);
				if(m.containsKey(key)){
					return m.valAt(key);
				}
				return notFound;
			}
			else if(key is Number && (coll is String || coll is Array || coll is IVector))
			{
				var n:int = int(key);
				return n >= 0 && n < count(coll) ? nth(coll, n) : notFound;
			}
			return notFound;
		}


		public static function nth(coll:Object, n:int, notFound:Object = null):Object{
			if(coll == null){
				return notFound;
			}
			else if(coll is IVector){
				return IVector(coll).nth(n) || notFound;
			}
			else if(coll is String){
				if(String(coll).length > n){
					return String(coll).charAt(n);
				}
				return notFound;
			}
			else if(coll is Array){
				return coll[n] || notFound;
			}
			else if(coll is ISeq)
			{
				var seq:ISeq = ISeq(coll);
				for(var i:int = 0; i <= n && seq != null; ++i, seq = seq.rest())
				{
					if(i == n)
					return seq.first();
				}
				return notFound;
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

		public static function concat(...all:Array):ISeq{
			var len:int = all.length;
			var x:Object = all[0];
			var y:Object = all[1];
			if(len == 0){
				return null;
			}
			else if(len == 1){
				return seq(x);
			}
			else if(len == 2){
				if(x){
					return cons(first(x), concat(rest(x), y));
				}
				else{
					return seq(y);
				}
			}
			else{
				var cat:Function = function(x:Object, y:Object, rest:Array):ISeq{
					var xy:ISeq = concat(x, y);
					if(rest.length == 0){
						return xy;
					}
					else{
						return cat(xy, rest[0], rest.slice(1));
					}
				};
				return cat(x, y, all.slice(2));
			}
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
			else if(coll is Array){
				return Vector.createFromArray(coll as Array).seq();
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
			return Var.internNS(LispNamespace.findOrCreate(this, sym2(null, ns)), sym2(null, name));
		}

		public static function restFromArguments(a:Array, i:int):List{
			if(i > (a.length - 1)) return null;
			return List.createFromArray(a.slice(i));
		}


		public function printToString(x:Object):String {
			var w:NaiveStringWriter = new NaiveStringWriter();
			print(x, w);
			return w.toString();
		}

		public function print(x:Object, w:NaiveStringWriter):void {
			//TODO - make extensible
			var readably:Boolean = Boolean(PRINT_READABLY.get());
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


	private function printInnerSeq(x:ISeq, w:NaiveStringWriter):void{
		for(var sq:ISeq = x; sq != null; sq = sq.rest())
		{
			print(sq.first(), w);
			if(sq.rest() != null)
			w.write(' ');
		}
	}


}
}