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

    import com.las3r.jdk.io.PushbackReader;
    import com.las3r.jdk.io.Reader;
    import com.las3r.util.*;

    public class LispReader{

		public var QUOTE:Symbol;
		public var THE_VAR:Symbol;
		public var FN:Symbol;
		public var _AMP_:Symbol;
		public var CONCAT:Symbol;
		public var LIST:Symbol;
		public var APPLY:Symbol;
		public var HASHMAP:Symbol;
		public var HASHSET:Symbol;
		public var VECTOR:Symbol;
		public var WITH_META:Symbol;
		public var META:Symbol;
		public var DEREF:Symbol;
		public var SLASH:Symbol;

		private var _rt:RT;

		public var symbolPat:RegExp = new RegExp("^[:]?([^0-9:/][^/]*/)?([^0-9:/][^/]*)$");
		public var intPat:RegExp = new RegExp("^([-+]?)(?:(0)|([1-9][0-9]*)|0[xX]([0-9A-Fa-f]+)|0([0-7]+)|([1-9][0-9]?)[rR]([0-9A-Za-z]+)|0[0-9]+)\\.?$");
		public var ratioPat:RegExp = new RegExp("^([-+]?[0-9]+)/([0-9]+)$");
		public var floatPat:RegExp = new RegExp("^[-+]?[0-9]+(\\.[0-9]+)?([eE][-+]?[0-9]+)?[M]?$");
		public var macros:IMap;
		public var dispatchMacros:IMap;


		//symbol->gensymbol
		//	static Var GENSYM_ENV = Var.create(null);
		//sorted-map num->gensymbol
		//	static Var ARG_ENV = Var.create(null);


		public function LispReader(rt:RT){
			_rt = rt;

			QUOTE = Symbol.intern2(_rt, null, "quote");
			THE_VAR = Symbol.intern2(_rt, null, "var");
			FN = Symbol.intern1(_rt, "fn*");
			_AMP_ = Symbol.intern1(_rt, "&");
			CONCAT = Symbol.intern2(_rt, "clojure", "concat");
			LIST = Symbol.intern2(_rt, "clojure", "list");
			APPLY = Symbol.intern2(_rt, "clojure", "apply");
			HASHMAP = Symbol.intern2(_rt, "clojure", "hash-map");
			HASHSET = Symbol.intern2(_rt, "clojure", "hash-set");
			VECTOR = Symbol.intern2(_rt, "clojure", "vector");
			WITH_META = Symbol.intern2(_rt, "clojure", "with-meta");
			META = Symbol.intern2(_rt, "clojure", "meta");
			DEREF = Symbol.intern2(_rt, "clojure", "deref");

			macros = RT.map(
				CharUtil.DOUBLE_QUOTE, new StringReader(this),
				CharUtil.SEMICOLON, new CommentReader(this),
				CharUtil.SINGLE_QUOTE, new WrappingReader(this, QUOTE),
				CharUtil.AT, new WrappingReader(this, DEREF),
				CharUtil.CARROT, new WrappingReader(this, META),
				CharUtil.TILDE, new UnquoteReader(this),
				CharUtil.LPAREN, new ListReader(this),
				CharUtil.LBRACK, new VectorReader(this),
				CharUtil.LBRACE, new MapReader(this),
				CharUtil.BACK_SLASH, new CharacterReader(this),
				CharUtil.POUND, new DispatchReader(this),
				CharUtil.RPAREN, new UnmatchedDelimiterReader(this),
				CharUtil.RBRACK, new UnmatchedDelimiterReader(this),
				CharUtil.RBRACE, new UnmatchedDelimiterReader(this)
				// CharUtil.BACKTICK, new SyntaxQuoteReader(this, _rt),
			);

			dispatchMacros = RT.map(
				CharUtil.DOUBLE_QUOTE, new RegexReader(this),
				CharUtil.CARROT, new MetaReader(this)
			);
		}

		public function isWhitespace(ch:int):Boolean{
			return CharUtil.isWhitespace(ch);
		}

		public function unread(r:PushbackReader, ch:int):void{
			if(ch != -1)
			r.unread(ch);
		}

		public function read(r:PushbackReader, eofIsError:Boolean = false, eofValue:Object = -1):Object{
			try
			{
				for(; ;)
				{
					var ch:int = r.readOne();

					while(isWhitespace(ch)){
						ch = r.readOne();
					}

					if(ch == -1)
					{
						if(eofIsError)
						throw new Error("EOF while reading");
						return eofValue;
					}

					if(CharUtil.isDigit(ch))
					{
						var n:Object = readNumber(r, ch);
						return n;
					}

					var macroFn:IReaderMacro = getMacro(ch);
					if(macroFn != null)
					{
						var ret:Object = macroFn.invoke(r, ch);
						//no op macros return the reader
						if(ret == r)
						continue;
						return ret;
					}

					if(ch == CharUtil.PLUS || ch == CharUtil.MINUS)
					{
						var ch2:int = r.readOne();
						if(CharUtil.isDigit(ch2))
						{
							unread(r, ch2);
							var n:Object = readNumber(r, ch);
							return n;
						}
						unread(r, ch2);
					}

					var token:String = readToken(r, ch);
					return interpretToken(token);
				}
			}
			catch(e:Error)
			{
				// 				if(isRecursive || !(r instanceof LineNumberingPushbackReader))
				throw e;
				// 				LineNumberingPushbackReader rdr = (LineNumberingPushbackReader) r;
				// 				throw new Exception(String.format("ReaderError:(%d,1) %s", rdr.getLineNumber(), e.getMessage()), e);
			}
			return null;
		}

		public function readToken(r:PushbackReader, initch:int):String{
			var sb:String = "";
			sb += String.fromCharCode(initch);
			for(; ;)
			{
				var ch:int = r.readOne();
				if(ch == -1 || isWhitespace(ch) || isTerminatingMacro(ch))
				{
					unread(r, ch);
					return sb;
				}
				sb += String.fromCharCode(ch);
			}
			return null;
		}

		public function readNumber(r:PushbackReader, initch:int):Object{
			var sb:String = "";
			sb += String.fromCharCode(initch);
			for(; ;)
			{
				var ch:int = r.readOne();
				if(ch == -1 || isWhitespace(ch) || isMacro(ch))
				{
					unread(r, ch);
					break;
				}
				sb += String.fromCharCode(ch);
			}
			var s:String = sb;
			var n:Object = matchNumber(s);
			if(n == null)
			throw new Error("NumberFormatException: Invalid number: " + s);
			return n;
		}

		public function readUnicodeCharFromToken(token:String, offset:int, length:int, base:int):int{
			if(token.length != offset + length)
			throw new Error("IllegalArgumentException: Invalid unicode character: \\" + token);
			var uc:int = 0;
			for(var i:int = offset; i < offset + length; ++i)
			{
				var d:int = CharUtil.digit(token.charCodeAt(i), base);
				if(d == -1)
				throw new Error("IllegalArgumentException: Invalid digit: " + d);
				uc = uc * base + d;
			}
			return uc;
		}

		public function readUnicodeChar(r:PushbackReader, initch:int, base:int, length:int, exact:Boolean):int{
			var uc:int = CharUtil.digit(initch, base);
			if(uc == -1)
			throw new Error("IllegalArgumentException: Invalid digit: " + initch);
			var i:int = 1;
			for(; i < length; ++i)
			{
				var ch:int = r.readOne();
				if(ch == -1 || isWhitespace(ch) || isMacro(ch))
				{
					unread(r, ch);
					break;
				}
				var d:int = CharUtil.digit(ch, base);
				if(d == -1)
				throw new Error("IllegalArgumentException: Invalid digit: " + String.fromCharCode(ch));
				uc = uc * base + d;
			}
			if(i != length && exact)
			throw new Error("IllegalArgumentException: Invalid character length: " + i + ", should be: " + length);
			return uc;
		}

		public function interpretToken(s:String):Object{
			if(s == "nil")
			{
				return null;
			}
			else if(s == "true")
			{
				return RT.T;
			}
			else if(s == "false")
			{
				return RT.F;
			}
			else if(s == "/")
			{
				return SLASH;
			}
			var ret:Object = null;
			ret = matchSymbol(s);
			if(ret != null)
			return ret;

			throw new Error("Invalid token: " + s);
		}


		public function matchSymbol(s:String):Object{
			var m:Object = symbolPat.exec(s);
			if(m && m[0] == s){
				var ns:String = m[1];
				var name:String = m[2];
				if(ns != null && ns.match(/:\/$/) || name.match(/:$/) || s.match(/::/)){
					return null;
				}
				var isKeyword:Boolean = s.charCodeAt(0) == CharUtil.COLON;
				var sym:Symbol = Symbol.intern1(_rt, s.substring(isKeyword ? 1 : 0));
				if(isKeyword)
				return Keyword.intern1(_rt, sym);
				return sym;
			}
			return null;
		}


		public function matchNumber(s:String):Object{
			var m:Object = intPat.exec(s);
			if(m && m[0] == s){
				if(m[2] != null){
					return 0;
				}
				var negate:Boolean = (m[1] == "-");
				var n:String;
				var radix:int = 10;
				if((n = m[3]) != null)
				radix = 10;
				else if((n = m[4]) != null)
				radix = 16;
				else if((n = m[5]) != null)
				radix = 8;
				else if((n = m[7]) != null)
				radix = parseInt(m[6]);
				if(n == null)
				return null;
				return ((negate ? -1 : 1) * parseInt(n, radix));
			}
			m = floatPat.exec(s);
			if(m && m[0] == s)
			{
				if(s.charAt(s.length - 1) == 'M')
				return parseFloat(s.substring(0, s.length - 1));
				return parseFloat(s);
			}
			m = ratioPat.exec(s);
			if(m && m[0] == s)
			{
				return parseInt(m[1]) / parseInt(m[2]);
			}
			return null;
		}

		public function getMacro(ch:int):IReaderMacro{
			return IReaderMacro(macros.valAt(ch));
		}

		public function isMacro(ch:int):Boolean{
			return macros.containsKey(ch);
		}

		public function isTerminatingMacro(ch:int):Boolean{
			return (ch != CharUtil.POUND && macros.containsKey(ch));
		}

		public function readDelimitedList(delim:int, r:PushbackReader):Array{
			var a:Array = [];
			for(; ;)
			{
				var ch:int = r.readOne();

				while(isWhitespace(ch))
				ch = r.readOne();

				if(ch == -1)
				throw new Error("EOF while reading");

				if(ch == delim)
				break;

				var macroFn:IReaderMacro = getMacro(ch);
				if(macroFn != null)
				{
					var mret:Object = macroFn.invoke(r, ch);
					//no op macros return the reader
					if(mret != r){
						a.push(mret);
					}
				}
				else
				{
					unread(r, ch);
					var o:Object = read(r, true, null);
					if(o != r){
						a.push(o);
					}
				}
			}
			return a;
		}

	}
}


import com.las3r.jdk.io.PushbackReader;
import com.las3r.jdk.io.Reader;
import com.las3r.runtime.*;
import com.las3r.util.*;

interface IReaderMacro {
	function invoke(reader:Object, token:Object):Object;
}

class StringReader implements IReaderMacro{

	protected var _reader:LispReader;

	public function StringReader(reader:LispReader){
		_reader = reader;
	}

	public function invoke(reader:Object, doublequote:Object):Object{
		var sb:String = "";
		var r:Reader = Reader(reader);

		for(var ch:int = r.readOne(); ch != CharUtil.DOUBLE_QUOTE; ch = r.readOne())
		{
			if(ch == -1)
			throw new Error("EOF while reading string");
			if(ch == CharUtil.BACK_SLASH)	//escape
			{
				ch = r.readOne();
				if(ch == -1)
				throw new Error("EOF while reading string");
				switch(ch)
				{
					case CharUtil.T:
					ch = CharUtil.TAB;
					break;
					case CharUtil.R:
					ch = CharUtil.CR;
					break;
					case CharUtil.N:
					ch = CharUtil.LF;
					break;
					case CharUtil.BACK_SLASH:
					break;
					case CharUtil.DOUBLE_QUOTE:
					break;
					case CharUtil.B:
					ch = CharUtil.BACKSPACE;
					break;
					case CharUtil.F:
					ch = CharUtil.FORM_FEED;
					break;
					case CharUtil.U:
					{
						ch = r.readOne();
						if(CharUtil.isDigit(ch))
						ch = _reader.readUnicodeChar(PushbackReader(r), ch, 16, 4, true);
						else
						throw new Error("Invalid unicode escape: \\" + String.fromCharCode(ch));
						break;
					}
					default:
					{
						if(CharUtil.isDigit(ch))
						{
							ch = _reader.readUnicodeChar(PushbackReader(r), ch, 8, 3, false);
							if(ch > 0377)
							throw new Error("Octal escape sequence must be in range [0, 377].");
						}
						else
						throw new Error("Unsupported escape character: \\" + String.fromCharCode(ch));
					}
				}
			}
			sb += String.fromCharCode(ch);
		}
		return sb;
	}
}



class CommentReader implements IReaderMacro{

	protected var _reader:LispReader;

	public function CommentReader(reader:LispReader){
		_reader = reader;
	}

	public function invoke(reader:Object, semicolon:Object):Object{
		var r:Reader = Reader(reader);
		var ch:int;
		do
		{
			ch = r.readOne();
		} while(ch != -1 && ch != CharUtil.LF && ch != CharUtil.CR);
		return r;
	}

}

class MetaReader implements IReaderMacro{

	protected var _reader:LispReader;

	public function MetaReader(reader:LispReader){
		_reader = reader;
	}

	public function invoke(reader:Object, semicolon:Object):Object{
		var r:PushbackReader = PushbackReader(reader);
		var line:int = -1;
// TODO: Aemon do this..		
// 		if(r is LineNumberingPushbackReader)
// 		line = ((LineNumberingPushbackReader) r).getLineNumber();

		var meta:Object = _reader.read(r, true, null)
		if(meta is Symbol || meta is Keyword || meta is String)
		meta = RT.map(RT.TAG_KEY, meta);
		else if(!(meta is IMap))
		throw new Error("IllegalArgumentException: Metadata must be Symbol,Keyword,String or Map");

		var o:Object = _reader.read(r, true, null);
		if(o is IObj)
		{
// 			if(line != -1 && o instanceof ISeq)
// 			meta = ((IPersistentMap) meta).assoc(RT.LINE_KEY, line);
			return (IObj(o).withMeta(IMap(meta)));
		}
		else
		throw new Error("IllegalArgumentException: Metadata can only be applied to IObjs");
	}

}


class DispatchReader implements IReaderMacro{

	protected var _reader:LispReader;

	public function DispatchReader(reader:LispReader){
		_reader = reader;
	}

	public function invoke(reader:Object, hash:Object):Object{
		var ch:int = (Reader(reader)).readOne();
		if(ch == -1)
		throw new Error("EOF while reading character");
		var fn:IReaderMacro = IReaderMacro(_reader.dispatchMacros.valAt(ch));
		if(fn == null)
		throw new Error("No dispatch macro for: " + String.fromCharCode(ch));
		return fn.invoke(reader, ch);
	}
}


class ListReader implements IReaderMacro{

	protected var _reader:LispReader;

	public function ListReader(reader:LispReader){
		_reader = reader;
	}

	public function invoke(reader:Object, leftparen:Object):Object{
		var r:PushbackReader = PushbackReader(reader);
		var list:Array = _reader.readDelimitedList(CharUtil.RPAREN, r);
		if(list.length == 0)
		return List.EMPTY;
		var s:IObj = IObj(List.createFromArray(list));
		return s;
	}
}


class MapReader implements IReaderMacro{

	protected var _reader:LispReader;

	public function MapReader(reader:LispReader){
		_reader = reader;
	}


	public function invoke(reader:Object, leftparen:Object):Object{
		var r:PushbackReader = PushbackReader(reader);
		return Map.createFromArray(_reader.readDelimitedList(CharUtil.RBRACE, r));
	}
}



class RegexReader implements IReaderMacro{

	protected var _reader:LispReader;

	public function RegexReader(reader:LispReader){
		_reader = reader;
	}

	public function invoke(reader:Object, doublequote:Object):Object{
		var stringrdr:StringReader = new StringReader(LispReader(_reader));
		var str:String = String(stringrdr.invoke(reader, doublequote));
		return new RegExp(str, "");
	}

}


class CharacterReader implements IReaderMacro{

	protected var _reader:LispReader;

	public function CharacterReader(reader:LispReader){
		_reader = reader;
	}

	public function invoke(reader:Object, backslash:Object):Object{
		var r:PushbackReader = PushbackReader(reader);
		var ch:int = r.readOne();
		if(ch == -1){
			throw new Error("EOF while reading character");
		}
		var token:String = _reader.readToken(r, ch);
		if(token.length == 1)
		return token.charAt(0);
		else if(token == "newline")
		return String.fromCharCode(CharUtil.LF);
		else if(token == "space")
		return String.fromCharCode(CharUtil.SPACE);
		else if(token == "tab")
		return String.fromCharCode(CharUtil.TAB);
		else if(token == "backspace")
		return String.fromCharCode(CharUtil.BACKSPACE);
		else if(token == "formfeed")
		return String.fromCharCode(CharUtil.FORM_FEED);
		else if(token == "return")
		return String.fromCharCode(CharUtil.RETURN);
		else if(token.match(/^u/))
		return String.fromCharCode(_reader.readUnicodeCharFromToken(token, 1, 4, 16));
		else if(token.match(/^o/))
		{
			var len:int = token.length - 1;
			if(len > 3)
			throw new Error("Invalid octal escape sequence length: " + len);
			var uc:int = _reader.readUnicodeCharFromToken(token, 1, len, 8);
			if(uc > 0377)
			throw new Error("Octal escape sequence must be in range [0, 377].");
			return String.fromCharCode(uc);
		}
		throw new Error("Unsupported character: \\" + token);
	}
}



class UnmatchedDelimiterReader implements IReaderMacro{

	protected var _reader:LispReader;

	public function UnmatchedDelimiterReader(reader:LispReader){
		_reader = reader;
	}

	public function invoke(reader:Object, rightdelim:Object):Object{
		throw new Error("Unmatched delimiter: " + rightdelim);
	}
}


class UnquoteReader implements IReaderMacro{

	protected var _reader:LispReader;

	public function UnquoteReader(reader:LispReader){
		_reader = reader;
	}

	public function invoke(reader:Object, comma:Object):Object{
		var r:PushbackReader = PushbackReader(reader);
		var ch:int = r.readOne();
		if(ch == -1)
		throw new Error("EOF while reading character");
		if(ch == CharUtil.AT)
		{
			var o:Object = _reader.read(r, true, null);
			return new UnquoteSplicing(o);
		}
		else
		{
			_reader.unread(r, ch);
			var o:Object = _reader.read(r, true, null);
			return new Unquote(o);
		}
	}
}


class VectorReader implements IReaderMacro{

	protected var _reader:LispReader;

	public function VectorReader(reader:LispReader){
		_reader = reader;
	}

	public function invoke(reader:Object, leftparen:Object):Object{
		var r:PushbackReader = PushbackReader(reader);
		return Vector.createFromArray(_reader.readDelimitedList(CharUtil.RBRACK, r));
	}
}



class WrappingReader implements IReaderMacro{
	var sym:Symbol;

	protected var _reader:LispReader;

	public function WrappingReader(reader:LispReader, sym:Symbol){
		_reader = reader;
		this.sym = sym;
	}

	public function invoke(reader:Object, quote:Object):Object{
		var r:PushbackReader = PushbackReader(reader);
		var o:Object = _reader.read(r, true, null);
		return RT.list2(sym, o);
	}

}