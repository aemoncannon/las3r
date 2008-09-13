package com.hurlant.eval.parse
{
	public class Char
	{
	    public static const EOS = 0;
	    public static const a = "a".charCodeAt(0);
	    public static const b = "b".charCodeAt(0);
	    public static const c = "c".charCodeAt(0);
	    public static const d = "d".charCodeAt(0);
	    public static const e = "e".charCodeAt(0);
	    public static const f = "f".charCodeAt(0);
	    public static const g = "g".charCodeAt(0);
	    public static const h = "h".charCodeAt(0);
	    public static const i = "i".charCodeAt(0);
	    public static const j = "j".charCodeAt(0);
	    public static const k = "k".charCodeAt(0);
	    public static const l = "l".charCodeAt(0);
	    public static const m = "m".charCodeAt(0);
	    public static const n = "n".charCodeAt(0);
	    public static const o = "o".charCodeAt(0);
	    public static const p = "p".charCodeAt(0);
	    public static const q = "q".charCodeAt(0);
	    public static const r = "r".charCodeAt(0);
	    public static const s = "s".charCodeAt(0);
	    public static const t = "t".charCodeAt(0);
	    public static const u = "u".charCodeAt(0);
	    public static const v = "v".charCodeAt(0);
	    public static const w = "w".charCodeAt(0);
	    public static const x = "x".charCodeAt(0);
	    public static const y = "y".charCodeAt(0);
	    public static const z = "z".charCodeAt(0);
	    public static const A = "A".charCodeAt(0);
	    public static const B = "B".charCodeAt(0);
	    public static const C = "C".charCodeAt(0);
	    public static const D = "D".charCodeAt(0);
	    public static const E = "E".charCodeAt(0);
	    public static const F = "F".charCodeAt(0);
	    public static const G = "G".charCodeAt(0);
	    public static const H = "H".charCodeAt(0);
	    public static const I = "I".charCodeAt(0);
	    public static const J = "J".charCodeAt(0);
	    public static const K = "K".charCodeAt(0);
	    public static const L = "L".charCodeAt(0);
	    public static const M = "M".charCodeAt(0);
	    public static const N = "N".charCodeAt(0);
	    public static const O = "O".charCodeAt(0);
	    public static const P = "P".charCodeAt(0);
	    public static const Q = "Q".charCodeAt(0);
	    public static const R = "R".charCodeAt(0);
	    public static const S = "S".charCodeAt(0);
	    public static const T = "T".charCodeAt(0);
	    public static const U = "U".charCodeAt(0);
	    public static const V = "V".charCodeAt(0);
	    public static const W = "W".charCodeAt(0);
	    public static const X = "X".charCodeAt(0);
	    public static const Y = "Y".charCodeAt(0);
	    public static const Z = "Z".charCodeAt(0);
	    public static const Zero = "0".charCodeAt(0);
	    public static const One = "1".charCodeAt(0);
	    public static const Two = "2".charCodeAt(0);
	    public static const Three = "3".charCodeAt(0);
	    public static const Four = "4".charCodeAt(0);
	    public static const Five = "5".charCodeAt(0);
	    public static const Six = "6".charCodeAt(0);
	    public static const Seven = "7".charCodeAt(0);
	    public static const Eight = "8".charCodeAt(0);
	    public static const Nine = "9".charCodeAt(0);
	    public static const Dot = ".".charCodeAt(0);
	    public static const Bang = "!".charCodeAt(0);
	    public static const Equal = "=".charCodeAt(0);
	    public static const Percent = "%".charCodeAt(0);
	    public static const Ampersand = "&".charCodeAt(0);
	    public static const Asterisk = "*".charCodeAt(0);
	    public static const Plus = "+".charCodeAt(0);
	    public static const Dash = "-".charCodeAt(0);
	    public static const Slash = "/".charCodeAt(0);
	    public static const BackSlash = "\\".charCodeAt(0);
	    public static const Comma = ",".charCodeAt(0);
	    public static const Colon = ":".charCodeAt(0);
	    public static const Semicolon = ";".charCodeAt(0);
	    public static const LeftAngle = "<".charCodeAt(0);
	    public static const RightAngle = ">".charCodeAt(0);
	    public static const Caret = "^".charCodeAt(0);
	    public static const Bar = "|".charCodeAt(0);
	    public static const QuestionMark = "?".charCodeAt(0);
	    public static const LeftParen = "(".charCodeAt(0);
	    public static const RightParen = ")".charCodeAt(0);
	    public static const LeftBrace = "{".charCodeAt(0);
	    public static const RightBrace = "}".charCodeAt(0);
	    public static const LeftBracket = "[".charCodeAt(0);
	    public static const RightBracket = "]".charCodeAt(0);
	    public static const Tilde = "~".charCodeAt(0);
	    public static const At = "@".charCodeAt(0);
	    public static const SingleQuote = "'".charCodeAt(0);
	    public static const DoubleQuote = "\"".charCodeAt(0);
	    public static const UnderScore = "_".charCodeAt(0);
	    public static const Dollar = "$".charCodeAt(0);
	    public static const Space = " ".charCodeAt(0);
	    public static const Tab = "\t".charCodeAt(0);
	    public static const VerticalTab = "\v".charCodeAt(0);
	    public static const Newline = "\n".charCodeAt(0);
	    public static const CarriageReturn = "\r".charCodeAt(0);
	    // inexplicably missing constants from Char :((. WTF is going on?
	    public static const Backspace = "\b".charCodeAt(0);
	    public static const Formfeed = "\f".charCodeAt(0);
	    public static const Minus = Dash;
	
	    public static function fromOctal (str)
		: int
	    {
		return parseInt (str);
	    }
	
	    public static function fromHex (str)
		: int
	    {
		return parseInt (str);
	    }
	
	    public static function isIdentifierStart(c) {
	        if (c >= Char.A && c <= Char.Z) return true;
	        else if (c >= Char.a && c <= Char.z) return true;
	        else if (c == Char.UnderScore) return true;
	        else if (c == Char.Dollar) return true;
	        return false;
	    }
	
	    public static function isDigit (c) {
	        if (c >= Char.Zero && c <= Char.Nine) return true;
	        return false;
	    }
	
	    public static function isIdentifierPart(c) {
	        if (isIdentifierStart (c)) return true;
	        else if (isDigit (c)) return true;
	        return false;
	    }
	
	
	    public static function test () {
			trace ("testing lex-char.es");
	        trace ("Space=",Space);
	        trace ("Tab=",Tab);
	        trace ("Newline=",Newline);
	    }
	
	    //Char.test ();
	
	}
}