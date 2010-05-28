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
	

	import com.las3r.io.*;
	import com.las3r.jdk.io.*;
	import com.las3r.runtime.LispNamespace;
	import com.las3r.runtime.Var;
	import com.las3r.runtime.Frame;
	import com.las3r.errors.RuntimeError;
	import com.las3r.util.StringBuffer;
	import com.las3r.util.Benchmarks;
	import com.las3r.util.RegExpUtil;
	import flash.events.*;
	import flash.display.Stage;
	import flash.utils.Dictionary;
	import flash.utils.ByteArray;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	import flash.utils.describeType;
	import flash.utils.getTimer;
	import com.hurlant.eval.ByteLoader;
	import org.pranaframework.reflection.Type;

	public class RT extends EventDispatcher{

		[Embed(source="../../../../../lib/las3r.core.swf", mimeType="application/octet-stream")]
		protected const CoreSwf:Class;
		[Embed(source="../../../../../lib/las3r.flash.swf", mimeType="application/octet-stream")]
		protected const FlashSwf:Class;
		[Embed(source="../../../../lsr/las3r.core.lsr", mimeType="application/octet-stream")]
		protected const CoreLsr:Class;
		[Embed(source="../../../../lsr/las3r.flash.lsr", mimeType="application/octet-stream")]
		protected const FlashLsr:Class;

		public static var instances:Object = {};
		public static var modules:Object = {};

		public var internedStrings:Object = {};
		public var internedSymbols:Dictionary = new Dictionary();
		public var internedKeywords:Dictionary = new Dictionary();
		public var namespaces:IMap = RT.map();
		private var specials:IMap;
		public var dvals:Frame = new Frame();


		public var stdout:OutputStream;
		public var stderr:OutputStream;
		public var stdin:InputStream;

		private var id:int = 1;
		private var _this:RT;
		private var _resultsDict:Dictionary = new Dictionary();
		private var _evalQ:Array = [];

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
		public var OUT:Var;
		public var IN:Var;
		public var SAVE_BYTECODES:Var;
		public var AOT_MODULE_SWF:Var;
		public var PRINT_READABLY:Var;
		public var TAG_KEY:Keyword;
		public var MACRO_KEY:Keyword;
		public var BYTECODES_KEY:Keyword;
		public var PRIVATE_KEY:Keyword;
		public var NAME_KEY:Keyword;
		public var LINE_KEY:Keyword;
		public var NS_KEY:Keyword;


		public var CONCAT:Symbol;
		public var APPLY:Symbol;
		public var WITH_META:Symbol;
		public var META:Symbol;
		public var SLASH:Symbol;
		public var LAS3R_SLASH:Symbol;
		public var DEREF:Symbol;


		// Special forms..
		public var DEF:Symbol;
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
				sym1("Error"), Error,
				sym1("RegExp"), RegExp,
				sym1("Array"), Array,
				sym1("XML"), XML,
				sym1("trace"), trace
			);
		}

		public function RT(stage:Stage = null, out:OutputStream = null, err:OutputStream = null, inn:InputStream = null):void{
			_this = this;
			_stage = stage;
			stdout = out || new TraceStream();
			stderr = err || new TraceStream();
			stdin = inn || new InputStream();
			var forceImport:Array = [Numbers, LazyCons, Range, StringBuffer, 
				PersistentArrayMap, PersistentStructMap, RuntimeError, Benchmarks, MultiFn];

			TAG_KEY = key1(sym1("tag"));
			MACRO_KEY = key1(sym1("macro"));
			BYTECODES_KEY = key1(sym1("bytecodes"));
			PRIVATE_KEY = key1(sym1("private"));
			NS_KEY = key1(sym1("ns"));
			NAME_KEY = key1(sym1("name"));
			LINE_KEY = key1(sym1("line"));

			LAS3R_NAMESPACE = LispNamespace.findOrCreate(this, sym1(LispNamespace.LAS3R_NAMESPACE_NAME));
			CURRENT_NS = Var.internWithRoot(LAS3R_NAMESPACE, sym1("*ns*"), LAS3R_NAMESPACE);
			RUNTIME = Var.internWithRoot(LAS3R_NAMESPACE, sym1("*runtime*"), this);
			STAGE = Var.internWithRoot(LAS3R_NAMESPACE, sym1("*stage*"), _stage);
			OUT = Var.internWithRoot(LAS3R_NAMESPACE, sym1("*out*"), stdout);
			IN = Var.internWithRoot(LAS3R_NAMESPACE, sym1("*in*"), stdin);
			OUT = Var.internWithRoot(LAS3R_NAMESPACE, sym1("*err*"), stderr);
			PRINT_READABLY = Var.internWithRoot(LAS3R_NAMESPACE, sym1("*print-readably*"), T);
			SAVE_BYTECODES = Var.internWithRoot(LAS3R_NAMESPACE, sym1("*save-bytecodes*"), F);
			AOT_MODULE_SWF = Var.internWithRoot(LAS3R_NAMESPACE, sym1("*aot-swf*"), null);

			/* 
			The following symbols will be spliced into macro-generated code, 
			so we want to make sure that they will resolve to the correct namespaced
			value. Hence the redefinition as a namespaced symbol. 
			*/

			IN_NAMESPACE = sym1("in-ns");
			Var.internWithRoot(LAS3R_NAMESPACE, IN_NAMESPACE, 
				function(nsname:Symbol):LispNamespace{
					var ns:LispNamespace = LispNamespace.findOrCreate(_this, nsname);
					CURRENT_NS.set(ns);
					return ns;
				});
			IN_NAMESPACE = sym2(LispNamespace.LAS3R_NAMESPACE_NAME, "in-ns");

			LOAD_FILE = sym1("load-file");
			Var.internWithRoot(LAS3R_NAMESPACE, LOAD_FILE,
				function(arg1:Object):Object{
					//return Compiler.loadFile(String(arg1));
					return null;
				});
			LOAD_FILE = sym2(LispNamespace.LAS3R_NAMESPACE_NAME, "load-file");

			IDENTICAL = sym1("identical?");
			Var.internWithRoot(LAS3R_NAMESPACE, IDENTICAL,
				function(arg1:Object, arg2:Object):Object{
					return arg1 == arg2 ? RT.T : RT.F;
				});
			IDENTICAL = sym2(LispNamespace.LAS3R_NAMESPACE_NAME, "identical?");

			CONCAT = sym1("concat");
			Var.internWithRoot(LAS3R_NAMESPACE, CONCAT,
				function(...args:Array):Object{
					return RT.concat.apply(null, args);
				});
			CONCAT = sym2(LispNamespace.LAS3R_NAMESPACE_NAME, "concat");

			APPLY = sym1("apply*");
			Var.internWithRoot(LAS3R_NAMESPACE, APPLY,
				function(func:Function, args:ISeq):Object{
					var ar:Array = [];
					for(var c:ISeq = args; c != null; c = c.rest()){ ar.push(c.first()); }
					return func.apply(null, ar);
				});
			APPLY = sym2(LispNamespace.LAS3R_NAMESPACE_NAME, "apply*");

			VECTOR = sym1("vector");
			Var.internWithRoot(LAS3R_NAMESPACE, VECTOR,
				function(...args:Array):Object{
					return PersistentVector.createFromArray(args);
				});
			VECTOR = sym2(LispNamespace.LAS3R_NAMESPACE_NAME, "vector");

			HASHMAP = sym1("hash-map");
			Var.internWithRoot(LAS3R_NAMESPACE, HASHMAP,
				function(...args:Array):Object{
					return PersistentHashMap.createFromArray(args);
				});
			HASHMAP = sym2(LispNamespace.LAS3R_NAMESPACE_NAME, "hash-map");

			LIST = sym1("list");
			Var.internWithRoot(LAS3R_NAMESPACE, LIST,
				function(...args:Array):Object{
					return List.createFromArray(args);
				});
			LIST = sym2(LispNamespace.LAS3R_NAMESPACE_NAME, "list");


			WITH_META = sym1("with-meta");
			Var.internWithRoot(LAS3R_NAMESPACE, WITH_META,
				function(x:Object, m:Object):Object{
					return x.withMeta(m);
				});
			WITH_META = sym2(LispNamespace.LAS3R_NAMESPACE_NAME, "with-meta");

			META = sym2(LispNamespace.LAS3R_NAMESPACE_NAME, "meta");

			DEREF = sym2(LispNamespace.LAS3R_NAMESPACE_NAME, "deref");

			SLASH = sym2(null, "/"); // Don't want namespace.
			LAS3R_SLASH = sym2(LispNamespace.LAS3R_NAMESPACE_NAME, "/");


			DEF = sym1("def");
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
			NEW = sym1("new");
			_AMP_ = sym1("&");
			ISEQ = sym1("com.las3r.runtime.ISeq");

			specials = RT.map(
				DEF,T,
				RECUR,T,
				IF,T,
				LET,T,
				DO,T,
				FN,T,
				QUOTE,T,
				THE_VAR,T,
				DOT,T,
				ASSIGN,T,
				TRY,T,
				CATCH,T, 
				FINALLY,T, 
				THROW,T,
				NEW,T,
				_AMP_,T
			);

			_compiler = new Compiler(this);
			_lispReader = new LispReader(this);

			// *ns* must be bound for (in-ns ...) to work..
			Var.pushBindings(this,
				RT.map(
					CURRENT_NS, CURRENT_NS.get(),
					SAVE_BYTECODES, SAVE_BYTECODES.get(),
					AOT_MODULE_SWF, AOT_MODULE_SWF.get(),
					RUNTIME, RUNTIME.get(),
					STAGE, STAGE.get(),
					OUT, OUT.get(),
					IN, IN.get(),
					PRINT_READABLY, PRINT_READABLY.get()
				)
			);
		}

		/* Cleanup function for an RT instance */
		public function dispose():void{
			Var.popBindings(this);
		}


		public function loadStdLib(onComplete:Function = null, progress:Function = null, failure:Function = null, fromSrc:Boolean = false):void{
			var src:String;
			var bytes:ByteArray;

			if(fromSrc){
				src = ByteArray(new CoreLsr).toString();
				evalStr(src, function(val:*):void{}, progress, failure);

				src = ByteArray(new FlashLsr).toString();
				evalStr(src, onComplete, progress, failure);
			}
			else{
				bytes = ByteArray(new CoreSwf);
				loadModule("las3r.core", bytes, function(val:*):void{}, failure);

				bytes = ByteArray(new FlashSwf);
				loadModule("las3r.flash", bytes, onComplete, failure);
			}
		}


		/**
		* Add the task of evaluating swfBytes to the work queue.
		* 
		*/	
		public function loadModule(moduleId:String, swfBytes:ByteArray, callback:Function, errorCallback:Function):void{
			var c:Function = callback;
			var p:Function = function(a:int, b:int):void{};
			var f:Function = errorCallback;
			queueEvalUnit(new SWFModuleEvalUnit(moduleId, swfBytes, c, f, p));
		}


		/**
		* Add the task of evaluating src to the work queue.
		* 
		*/		
		public function evalStr(src:String, onComplete:Function = null, progress:Function = null, onFailure:Function = null):void{
			var c:Function = onComplete || function(v:*):void{};
			var p:Function = progress || function(a:int, b:int):void{};
			var f:Function = onFailure || function(e:*):void{};
			var reader:PushbackReader = new LineNumberingPushbackReader(new StringReader(src));
			queueEvalUnit(new ReaderEvalUnit(reader, c, f, p));
		}

		protected function queueEvalUnit(unit:EvalUnit):void{
			_evalQ.push(unit);
			if(_evalQ.length == 1) evalNextInQ();
		}

		protected function evalNextInQ():void{
			if(_evalQ.length > 0){
				var next:EvalUnit = EvalUnit(_evalQ[0]);

				var completeWrapper:Function = function(val:*){
					next.finished(val);					
					removeFromEvalQ(next);
					if(_evalQ.length > 0) evalNextInQ();
				};
				var errorWrapper:Function = function(error:*){
					next.error(error);
					removeFromEvalQ(next);
					if(_evalQ.length > 0) evalNextInQ();
				};

				if(next is SWFModuleEvalUnit){
					var moduleId:String = SWFModuleEvalUnit(next).moduleId;
					var bytes:ByteArray = SWFModuleEvalUnit(next).bytes;
					ByteLoader.loadBytes(bytes, function():void{
							var moduleConstructor:Function = RT.modules[moduleId];
							if(!(moduleConstructor is Function)) {
								throw new Error("IllegalStateException: no module constructor at " + moduleId);
							}
							moduleConstructor(_this, completeWrapper, errorWrapper);
						}, 
						true
					);
				}
				else if(next is ReaderEvalUnit){
					_compiler.load(ReaderEvalUnit(next).reader, completeWrapper, errorWrapper, next.progress);
				}
				
			}
		}
		
		protected function removeFromEvalQ(obj:EvalUnit):void{
			var i:int = _evalQ.indexOf(obj);
			if(i > -1) _evalQ.splice(i, 1);
		}
		
		public function isSpecial(sym:Object):Boolean{
			return specials.valAt(sym) === T;
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
				return sym2(null, nameForClass(Class(o)));
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
				return RT.classForName(sym.name);
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

		public function currentNS():LispNamespace{
			return LispNamespace(CURRENT_NS.get());
		}

		public static function classForInstance(o:Object):Class{
			return Object(o).constructor;
		}

		public static function classForName(name:String):Class{
			return (getDefinitionByName(name) as Class);
		}

		public static function objectForName(name:String):Object{
			return (getDefinitionByName(name));
		}

		public static function nameForClass(clazz:Class):String{
			var s:String = getQualifiedClassName(clazz);
			return s.replace("::", ".");
		}

		public static function nameForInstanceClass(obj:Object):String{
			var s:String = getQualifiedClassName(obj);
			return s.replace("::", ".");
		}

		public static function getSuperClass(clazz:Class):Class{
			var desc:XML = describeType(clazz);
			for each(var ea:String in desc.factory.extendsClass.@type){
				return classForName(ea);
			}
			return null;
		}

		public static function getSuperClasses(clazz:Class):ISeq{
			var desc:XML = describeType(clazz);
			var l:ISeq = RT.list();
			for each(var ea:String in desc.factory.extendsClass.@type){
				l = l.cons(classForName(ea));
			}
			return l;
		}

		public static function getInterfaces(clazz:Class):ISeq{
			var desc:XML = describeType(clazz);
			var l:ISeq = RT.list();
			for each(var ea:String in desc.factory.implementsInterface.@type){
				l = l.cons(classForName(ea));
			}
			return l;
		}

		public function writeToStdout(str:String):void{
			stdout.write(str);
		}

		public function writeToStderr(str:String):void{
			stderr.write(str);
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
			else if(o is ISeq)
			return (ISeq(o)).count();
			else if(o is IVector)
			return (IVector(o)).count();
			else if(o is IMap)
			return (IMap(o)).count();
			else if(o is ISet)
			return (ISet(o)).count();
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

		public static function numCast(x:Object):Number{
			return Number(x);
		}

		public static function sysTime():int { 
			return getTimer();
		}

		public static function intCast(x:Object):int{
			return int(x);
		}

		public static function conj(coll:Object, x:Object):Object{
			if(coll == null)
			return new List(x);
			return coll.cons(x);
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

		public static function keys(map:IMap):ISeq{
			return map.keys();
		}

		public static function vals(map:IMap):ISeq{
			return map.vals();
		}

		public static function nth(coll:Object, n:int, notFound:Object = null):Object{
			if(coll == null){
				return notFound;
			}
			else if(coll is IVector){
				return IVector(coll).nth(n);
			}
			else if(coll is String){
				if(String(coll).length > n){
					return String(coll).charAt(n);
				}
				return notFound;
			}
			else if(coll is Array){
				var val:* = coll[n];
				if(val === undefined) {
					if(notFound !== null) {
						return notFound;
					}
					throw new Error("IndexOutOfBoundsException");
				}
				return coll[n];
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

		public static function unzip(seq:ISeq):ISeq{
			var a:Array = [];
			var b:Array = [];

			var count:int = count(seq);
			if((count % 2) != 0)
			throw new Error("IllegalArgumentException: Bad argument to unzip, expected even number of args.");

			for(var sq:ISeq = seq; sq != null; sq = sq.rest().rest())
			{
				a.push(sq.first());
				b.push(sq.rest().first());
			}

			return RT.list(List.createFromArray(a), List.createFromArray(b));
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
			else if(coll is ISet){
				return ISet(coll).seq();
			}
			else if(coll is String){
				var s:String = String(coll);
				return s.length ? new StringSeq(s, 0) : null;
			}
			else if(coll is Array){
				return PersistentVector.createFromArray(coll as Array).seq();
			}
			else{
				throw new Error("IllegalArgumentException: Don't know how to create ISeq from " + coll);
			}
		}

		public static function contains(coll:Object, key:Object):Boolean{
			if(coll == null){
				return F;
			}
			else if(coll is IMap){
				return (IMap(coll).containsKey(key)) ? T : F;
			}
			else if(coll is ISet){
				return (ISet(coll).contains(key)) ? T : F;
			}
			else if(key is String && (coll is String))
			{
				return (String(coll).indexOf(String(key)) != -1) ? T : F;
			}
			else if((coll is Array))
			{
				return (((coll as Array).indexOf(key)) != -1) ? T : F;
			}
			else{
				return F;
			}
		}

		public static function assoc(o:Object, key:Object, val:Object):Object{

			/* TODO: This is too limited.
			Should accept anything that implements Associative. 
			(need to introduce Associative interface first)
			*/
			if(o === null){
				return map(key, val);
			}
			else if(o is IMap){
				return IMap(o).assoc(key, val);
			}
			else if(o is IVector){
				return IVector(o).assocN(int(key), val);
			}
			else throw new Error("Objects passed to assoc must implement IMap or IVector.");
		}

		public static function dissoc(map:IMap, key:Object):IMap{
			return map.without(key);
		}

		public static function set(...init:Array):ISet{
			if(init.length == 0){ return PersistentHashSet.empty(); }
			return PersistentHashSet.createFromArray(init);
		}

		public static function map(...init:Array):IMap{
			if(init.length == 0){ return PersistentHashMap.empty(); }
			return PersistentHashMap.createFromArray(init);
		}

		public static function vector(...init:Array):IVector{
			if(init.length == 0){ return PersistentVector.empty(); }
			else return PersistentVector.createFromArray(init);
		}

		public static function subvec(v:IVector, start:int, end:int):IVector{
			if(end < start || start < 0 || end > v.count())
			throw new Error("IndexOutOfBoundsException");

			if(start == end)
			return PersistentVector.empty();

			if(!v is APersistentVector)
			throw new Error("UnsupportedOperationException");

			return APersistentVector(v).subvec(start, end);
		}

		public static function meta(x:Object):IMap{
			if(x is IObj)
			return IObj(x).meta;
			return null;
		}

		public function getVar(ns:String, name:String):Var{
			return Var.internNS(LispNamespace.findOrCreate(this, sym2(null, ns)), sym2(null, name));
		}

		public static function seqToArray(seq:ISeq):Array{
			var ret:Array = []
			var items:ISeq = seq;
			for(; items != null; items = items.rest())
			ret.push(items.first());
			return ret;
		}

		public static function toArray(obj:Object):Array{
			if(obj is Array) return obj as Array;
			else if(obj is ISeq) return seqToArray(ISeq(obj));
			else if(obj is IVector) return IVector(obj).toArray();
			throw new Error("UnsupportedOperationException");
			return null;
		}

		public function propertyNamesList(object:Object):List{
			var result:Array = [];

			for(var iterant:String in object){
				result.push(iterant);
			}
			return List.createFromArray(result);
		}

		public function propertyValuesList(object:Object):List{
			var result:Array = [];
			for each(var iterant:* in object){
				result.push(iterant);
			}
			return List.createFromArray(result);
		}

		public function getPropertyByName(instance:Object, property:String) {
			return instance[property];
		}

		public function setPropertyByName(instance:Object, property:String, value:*) {
			return instance[property] = value;
		}

		public function readString(str:String):Object {
			var r:LineNumberingPushbackReader = new LineNumberingPushbackReader(new StringReader(str));
			return lispReader.read(r);
		}

		public function printString(x:Object):String {
			var w:NaiveStringWriter = new NaiveStringWriter();
			print(x, w);
			return w.toString();
		}

		public function print(x:Object, w:OutputStream):void {
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
						var v:MapEntry = MapEntry(sq.first());
						print(v.key, w);
						w.write(' ');
						print(v.value, w);
						if(sq.rest() != null)
						w.write(", ");
					}
					w.write('}');
			}
			else if(x is IVector)
			{
				var a:IVector = IVector(x);
				w.write('[');
					for(i = 0; i < a.count(); i++)
					{
						print(a.nth(i), w);
						if(i < a.count() - 1)
						w.write(' ');
					}
					w.write(']');
			}
			else if(x is ISet)
			{
				w.write("#{");
					for(var setSq:ISeq = seq(x); setSq != null; setSq = setSq.rest())
					{
						print(setSq.first(), w);
						if(setSq.rest() != null)
						w.write(" ");
					}
					w.write('}');
			}
			else if(x is RegExp)
			{
				var reS:String = String(x);
				var start:int = reS.indexOf("/");
				var end:int = reS.lastIndexOf("/");
				var qmode:Boolean = false;
				var ch:String;

				w.write("#\"");
				for(var idx:int = start + 1; idx < end;) {
					ch = reS.charAt(idx++);
					if(ch == "\\") {
						w.write(ch);
						w.write(ch = reS.charAt(idx++));
						qmode = qmode ? (ch != "E") : (ch == "Q");
					} else if (ch == "\"") {
						w.write(qmode ? "\\E\\\"\\Q" : "\\\"");
					} else {
					    w.write(ch);
					}
				}
				w.write("\"");

				w.write(RegExpUtil.flags(RegExp(x)));
			}
			else if(x is Class)
			{
				w.write("#=");
				w.write(nameForClass(Class(x)));
			}
			else if(x is Var)
			{
				var vr:Var = Var(x);
				w.write("#=(var " + vr.ns.name + "/" + vr.sym + ")");
			}
			else w.write(x.toString());
		}


		private function printInnerSeq(x:ISeq, w:OutputStream):void{
			for(var sq:ISeq = x; sq != null; sq = sq.rest())
			{
				print(sq.first(), w);
				if(sq.rest() != null)
				w.write(' ');
			}
		}


	}
}