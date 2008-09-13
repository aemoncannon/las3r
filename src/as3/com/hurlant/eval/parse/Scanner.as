package com.hurlant.eval.parse
{
	import com.hurlant.eval.Debug;
	
	public class Scanner
    {
        var src : String;
        var origin : String;
        var curIndex : int;
        var markIndex : int;
        var lastMarkIndex : int;
        var colCoord : int;
        var lnCoord : int;

        function Scanner (src:String, origin:String) {
            this.src = src;
            this.origin = origin;
            this.curIndex = 0;
            this.markIndex = 0;
            this.lastMarkIndex = 0;
            this.colCoord = 0;
            this.lnCoord = 0;
            // trace("scanning: ",src);
        }

        function next ()
            : int
        {
            if (curIndex == src.length)
            {
                curIndex++;
                return Char.EOS;
            }
            else
            {
                return src.charCodeAt(curIndex++);
            }
        }

        function lexeme()
            : String
        {
            return src.slice (markIndex,curIndex)
        }

        function retract()
            : void
        {
            curIndex--;
            //trace("retract cur=",curIndex);
        }

        function mark ()
            : void
        {
            markIndex = curIndex;
	    //trace("mark mark=",markIndex);
        }

        function tokenList (lexPrefix)
            //            : [[int],[[int,int]]]
        {
            import flash.utils.*;

            // trace ("scanning");
            function pushToken (token)
            {
                if (token == Token.Eol) {
                    lnCoord++;
                    colCoord = 0;
                }
                else {
                    //trace ("token ", token);
                    //trace ("token ", token, " \t", Token.tokenText(token));
                    colCoord = colCoord + markIndex - lastMarkIndex;
                    coordList.push ([lnCoord,colCoord]);
                    tokenArray.writeInt (token);
                    lastMarkIndex = markIndex;
                }
            }

            //var tokenList = new Array;
            var tokenArray = new ByteArray;
            var coordList = new Array;

            var token = lexPrefix ();
            pushToken (token);

            while (token != Token.BREAK &&
                   token != Token.EOS &&
                   token != Token.ERROR)
            {
                token = start ();
                pushToken (token);
            }

            //trace("tokenList = ",tokenList);
            //trace("coordList = ",coordList);
            return [tokenArray,coordList];
        }

        function regexp ()
        {
            var c = next ();
            switch (c)
            {
            case Char.Slash :
                return regexpFlags ();
	        case Char.EOS :
                throw "unexpected end of program in regexp literal";
            default:
                return regexp ();
            }
        }

        function regexpFlags ()
        {
            var c /*: int*/ = next ();
            if (Char.isIdentifierPart (c)) {
                return regexpFlags ();
            }
            else {
                retract ();
                return Token.makeInstance (Token.RegexpLiteral,lexeme());
            }
        }

        function start ()
            : int
        {
            var c /*: int*/;
            while (true)
            {
                mark();
                c = next();
                //trace("c[",curIndex-1,"]=",String.fromCharCode(c));
                switch (c) {
                //  case 0xffffffef: return utf8sig ();
                case Char.EOS: return Token.EOS;
                case Char.Slash: return slash ();
                case Char.Newline: return Token.Eol;
                case Char.CarriageReturn: return Token.Eol; // was start (); // ignore
                case Char.Space: return start ();
                case Char.Tab: return start ();
                case Char.LeftParen: return Token.LeftParen;
                case Char.RightParen: return Token.RightParen;
                case Char.Comma: return Token.Comma;
                case Char.Semicolon: return Token.SemiColon;
                case Char.QuestionMark: return Token.QuestionMark;
                case Char.LeftBracket: return Token.LeftBracket;
                case Char.RightBracket: return Token.RightBracket;
                case Char.LeftBrace: return Token.LeftBrace;
                case Char.RightBrace: return Token.RightBrace;
                case Char.Tilde: return Token.BitwiseNot;
                case Char.At: return Token.At;
                case Char.SingleQuote: return stringLiteral (c);
                case Char.DoubleQuote: return stringLiteral (c);
                case Char.Dot: return dot ();
                case Char.Dash: return minus ();
                case Char.Bang: return not ();
                case Char.Percent: return remainder ();
                case Char.Ampersand: return and ();
                case Char.Asterisk: return mult ();
                case Char.Colon: return colon ();
                case Char.Caret: return bitwiseXor ();
                case Char.Bar: return bitwiseOr ();
                case Char.Plus: return plus ();
                case Char.LeftAngle: return leftAngle ();
                case Char.Equal: return equal ();
                case Char.RightAngle: return rightAngle ();
                case Char.b: return b_ ();
                case Char.c: return identifier ("c");
                case Char.d: return d_ ();
                case Char.e: return identifier ("e");
                case Char.f: return identifier ("f");
                case Char.g: return identifier ("g");
                case Char.i: return identifier ("i");
                case Char.n: return n_ ();
                case Char.o: return identifier ("o");
                case Char.p: return identifier ("p");
                case Char.r: return identifier ("r");
                case Char.s: return identifier ("s");
                case Char.t: return identifier ("t");
                case Char.u: return identifier ("u");
                case Char.v: return identifier ("v");
                case Char.w: return identifier ("w");
                case Char.BackSlash:
                    var c = escapeSequence ();
                    return identifier (String.fromCharCode(c));
                case Char.Zero: return zero ();
                case Char.One:
                case Char.Two:
                case Char.Three:
                case Char.Four:
                case Char.Five:
                case Char.Six:
                case Char.Seven:
                case Char.Eight:
                case Char.Nine:
                    return decimalInteger ();
                default:
                    if (Char.isIdentifierStart (c))
                    {
                        return identifier (String.fromCharCode(c));
                    }
                    else
                    {
                        trace ("prefix=",c);
                        throw "scanning with invalid prefix ", c;
                    }
                }
            }
            Debug.assert(false);
            return int.MIN_VALUE; // never executed, but needed by as3 compiler.
	}

	function zero ()
	    : int
	{
	    var c /*: int*/ = next ();
	    switch (c) {
	    case Char.x:
	    case Char.X:
            return hexLiteral ();
	    case Char.Zero:
	    case Char.One:
	    case Char.Two:
	    case Char.Three:
	    case Char.Four:
	    case Char.Five:
	    case Char.Six:
	    case Char.Seven:
            return octalLiteral ();
	    case Char.Dot:
            return decimalInteger ();
	    case Char.Eight:  // what do we do with these?
	    case Char.Nine:
	    default :
            retract ();
            return numberSuffix ();
	    }
	}

	function hexLiteral ()
	    : int
	{
	    var c /*: int*/ = next ();
	    switch (c) {
	    case Char.Zero:
	    case Char.One:
	    case Char.Two:
	    case Char.Three:
	    case Char.Four:
	    case Char.Five:
	    case Char.Six:
	    case Char.Seven:
	    case Char.Eight:
	    case Char.Nine:
	    case Char.a: case Char.A:
	    case Char.b: case Char.B:
	    case Char.c: case Char.C:
	    case Char.d: case Char.D:
	    case Char.e: case Char.E:
	    case Char.f: case Char.F:
		return hexLiteral ();
	    default:
		retract ();
		return numberSuffix ();
	    }
	}

	function octalLiteral ()
	    : int
	{
	    var c /*: int*/ = next ();
	    switch (c) {
	    case Char.Zero:
	    case Char.One:
	    case Char.Two:
	    case Char.Three:
	    case Char.Four:
	    case Char.Five:
	    case Char.Six:
	    case Char.Seven:
		return octalLiteral ();
	    case Char.Eight:  // what do we do with these?
	    case Char.Nine:
	    default:
		retract ();
		return numberSuffix ();
	    }
	}

	function decimalInteger ()
	    : int
	{
	    var c /*: int*/ = next ();
	    switch (c) {
	    case Char.Zero:
	    case Char.One:
	    case Char.Two:
	    case Char.Three:
	    case Char.Four:
	    case Char.Five:
	    case Char.Six:
	    case Char.Seven:
	    case Char.Eight:
	    case Char.Nine:
            return decimalInteger ();
	    case Char.Dot:
            return decimalFraction ();
	    case Char.e: case Char.E:
            return decimalExponent ();
	    default:
            retract ();
            return numberSuffix ();
	    }
	}

	function decimalFraction ()
	    : int
	{
	    var c /*: int*/ = next ();
	    switch (c) {
	    case Char.Zero:
	    case Char.One:
	    case Char.Two:
	    case Char.Three:
	    case Char.Four:
	    case Char.Five:
	    case Char.Six:
	    case Char.Seven:
	    case Char.Eight:
	    case Char.Nine:
		return decimalFraction ();
	    case Char.e: case Char.E:
		switch (next()) {
		case Char.Plus:
		case Char.Minus:
		    return decimalExponent ();
		default:
		    retract ();
		    return decimalExponent ();
		}
	    default:
		retract ();
		return numberSuffix ();
	    }
	}

	function decimalExponent ()
	    : int
	{
	    var c /*: int*/ = next ();
	    switch (c) {
	    case Char.Zero:
	    case Char.One:
	    case Char.Two:
	    case Char.Three:
	    case Char.Four:
	    case Char.Five:
	    case Char.Six:
	    case Char.Seven:
	    case Char.Eight:
	    case Char.Nine:
		return decimalExponent ();
	    default:
		retract ();
		return numberSuffix ();
	    }
	}

	function numberSuffix ()
	    : int
	{
	    var c /*: int*/ = next ();
	    switch (c) {
	    case Char.i:
		return Token.makeInstance (Token.ExplicitIntLiteral, lexeme ());
	    case Char.u:
		return Token.makeInstance (Token.ExplicitUIntLiteral, lexeme ());
	    case Char.d:
		return Token.makeInstance (Token.ExplicitDoubleLiteral, lexeme ());
	    case Char.m:
		return Token.makeInstance (Token.ExplicitDecimalLiteral, lexeme ());
	    default:
		retract ();
		return Token.makeInstance (Token.DecimalLiteral, lexeme ());
	    }
	}

	function slash ()
	    : int
	{
	    var c /*: int*/ = next ();
	    switch (c) {
	    case Char.Slash:
		lineComment ();
		return start ();
	    case Char.Asterisk:
		blockComment ();
		return start ();
	    default:
		retract ();
		return Token.BREAK;
	    }
	}

	function lineComment ()
	    : void
	{
	    var c /*: int*/ = next ();
	    switch (c) {
	    case Char.Newline:
	    case Char.CarriageReturn:
	    case Char.EOS:
		retract (); // leave newline for asi
		return;
	    default:
		return lineComment ();
	    }
	}

	function blockComment ()
	    : void
	{
	    var c /*: int*/ = next ();
        while (true) {
	    switch (c) {
	    case Char.Asterisk :
            switch (next()) {
            case Char.Slash:
                return;
            case Char.EOS :
                retract ();
                return;
            case Char.Asterisk:
                retract (); // leave in case next char is a slash
                break;
            case Char.Newline:
                colCoord = 0;
                lnCoord++; // count ln and fall through
            default:
                break;
            }
            break;
	    case Char.EOS :
            retract ();
            return;
        case Char.Newline:
            lnCoord++; // fall through
	    default :
            break;
	    }
        c = next ();
        }
	}

	function stringLiteral (delimiter, text="")
	    : int
	{
	    var c /*: int*/ = next ();
        while (c != Char.EOS) {
            switch (c) {
            case delimiter:
                return Token.makeInstance (Token.StringLiteral, String.fromCharCode(delimiter)+text);
                // encode delimiter in string lexeme by appending to text
            case Char.BackSlash:
                c = escapeSequence ();
                text = text+String.fromCharCode(c);
                break;
            default:
                text = text+String.fromCharCode(c);
                break;
            }
            c = next ();
        }
        throw "unterminated string literal: " + text;

        /*
	    switch (c) {
	    case delimiter:
            return Token.makeInstance (Token.StringLiteral, String.fromCharCode(delimiter)+text);
            // encode delimiter in string lexeme by appending to text
	    case Char.BackSlash:
            var c = escapeSequence ();
            return stringLiteral (delimiter, text+String.fromCharCode(c));
	    default:
            return stringLiteral (delimiter, text+String.fromCharCode (c))
	    }
        */
	}

	/*

	*/

	function escapeSequence ()
	    : int
	{
	    var c /*: int*/ = next ();
	    switch (c) {
	    case Char.Zero:
	    case Char.One:
	    case Char.Two:
	    case Char.Three:
	    case Char.Four:
	    case Char.Five:
	    case Char.Six:
	    case Char.Seven:
            retract ();
            return octalOrNulEscape (0);
	    case Char.x:
            return hexEscape (2);
	    case Char.u:
            return hexEscape (4);
	    case Char.b:
            return Char.Backspace;
	    case Char.f:
            return Char.Formfeed;
	    case Char.n:
            return Char.Newline;
	    case Char.r:
            return Char.CarriageReturn;
	    case Char.t:
            return Char.Tab;
	    case Char.v:
            return Char.VerticalTab;
	    case Char.SingleQuote:
	    case Char.DoubleQuote:
	    case Char.BackSlash:
            return c;
        default:
            throw "lexer error escapeSequence " + c;
	    }
	}

	function octalOrNulEscape (n:int)
	    : uint
	{
	    var c /*: int*/ = next ();
	    switch (c) {
	    case Char.Zero:
		switch (next()) {
		case Char.One:
		case Char.Two:
		case Char.Three:
		case Char.Four:
		case Char.Five:
		case Char.Six:
		case Char.Seven:
		    retract ();
		    return octalEscapeFull (n+1);
		default:
		    return 0;  // \0
		}
	    case Char.One:
	    case Char.Two:
	    case Char.Three:
		return octalEscapeFull (n+1);
	    case Char.Four:
	    case Char.Five:
	    case Char.Six:
	    case Char.Seven:
		return octalEscapeShort (n+1);
	    default:
		throw "internal error: expecting octal character";
	    }
	}

	function octalEscapeFull (n:int)
	    : uint
	{
	    if (n==3) {
		for (var i=0; i<n; i++ ) retract ();  // unwind input for rescanning
		return octalEscape (n,0);
	    }

	    var c /*: int*/ = next ();
	    switch (c) {
	    case Char.Zero:
	    case Char.One:
	    case Char.Two:
	    case Char.Three:
	    case Char.Four:
	    case Char.Five:
	    case Char.Six:
	    case Char.Seven:
		return octalEscapeFull (n+1);
	    default:
		for (var i=0; i<=n; i++ ) retract ();  // unwind input for rescanning
		return octalEscape (n,0);
	    }
	}

	function octalEscapeShort (n:int)
	    : uint
	{
	    var c /*: int*/ = next ();
	    switch (c) {
	    case Char.Zero:
	    case Char.One:
	    case Char.Two:
	    case Char.Three:
	    case Char.Four:
	    case Char.Five:
	    case Char.Six:
	    case Char.Seven:
		for (var i=0; i<=n; i++ ) retract ();  // unwind input for rescanning
		return octalEscape (n+1,0);
	    default:
		for (var i=0; i<=n; i++ ) retract ();  // unwind input for rescanning
		return octalEscape (n,0);
	    }
	}

	function octalEscape (n:int,v:uint=0)
	    : uint
	{
	    if (n==0) {
		return v;
	    }

	    var c /*: int*/ = next ();
	    var m;
	    switch (c) {
	    case Char.Zero:
		m=0x0;
		break;
	    case Char.One:
		m=0x1;
		break;
	    case Char.Two:
		m=0x2;
		break;
	    case Char.Three:
		m=0x3;
		break;
	    case Char.Four:
		m=0x4;
		break;
	    case Char.Five:
		m=0x5;
		break;
	    case Char.Six:
		m=0x6;
		break;
	    case Char.Seven:
		m=0x7;
		break;
	    default:
		trace("error");
		throw "malformed escape, expecting "+n+" more characters";
	    }
	    return octalEscape (n-1, v+m*Math.pow(8,n-1));
	}

	function hexEscape (n:int,v:uint=0)
	    : uint
	{
	    if (n==0) {
		return v;
	    }

	    var c /*: int*/ = next ();
	    var m;
	    switch (c) {
	    case Char.Zero:
		m=0x0;
		break;
	    case Char.One:
		m=0x1;
		break;
	    case Char.Two:
		m=0x2;
		break;
	    case Char.Three:
		m=0x3;
		break;
	    case Char.Four:
		m=0x4;
		break;
	    case Char.Five:
		m=0x5;
		break;
	    case Char.Six:
		m=0x6;
		break;
	    case Char.Seven:
		m=0x7;
		break;
	    case Char.Eight:
		m=0x8;
		break;
	    case Char.Nine:
		m=0x9;
		break;
	    case Char.a: case Char.A:
		m=0xA;
		break;
	    case Char.b: case Char.B:
		m=0xB;
		break;
	    case Char.c: case Char.C:
		m=0xC;
		break;
	    case Char.d: case Char.D:
		m=0xD;
		break;
	    case Char.e: case Char.E:
		m=0xE;
		break;
	    case Char.f: case Char.F:
		m=0xF
		break;
	    default:
		trace("error");
		throw "malformed escape, expecting "+n+" more characters";
	    }
	    return hexEscape (n-1, v+m*Math.pow(16,n-1));
	}

	/*

	. .. ... .<

	*/

	function dot ()
	    : int
	{
	    var c /*: int*/ = next ();
	    switch (c) {
	    case Char.Dot : return dotdot ();
	    case Char.LeftAngle : return Token.LeftDotAngle;
	    case Char.Zero:
	    case Char.One:
	    case Char.Two:
	    case Char.Three:
	    case Char.Four:
	    case Char.Five:
	    case Char.Six:
	    case Char.Seven:
	    case Char.Eight:
	    case Char.Nine:
		return decimalFraction ();
	    default :
		retract ();
		return Token.Dot;
	    }
	}

	function dotdot ()
	    : int
	{
	    var c /*: int*/ = next ();
	    switch (c) {
	    case Char.Dot : return Token.TripleDot;
	    default :
		retract ();
		return Token.DoubleDot;
	    }
	}

	/*

	! != !==

	*/

	function not ()
	    : int
	{
	    var c /*: int*/ = next ();
	    switch (c) {
	    case Char.Equal : return notequal ();
	    default :
		retract ();
		return Token.Not;
	    }
	}

	function notequal ()
	    : int
	{
	    var c /*: int*/ = next ();
	    switch (c) {
	    case Char.Equal : return Token.StrictNotEqual;
	    default :
		retract ();
		return Token.NotEqual;
	    }
	}

	/*

	% %=

	*/

	function remainder ()
	    : int
	{
	    var c /*: int*/ = next ();
	    switch (c) {
	    case Char.Equal : return Token.RemainderAssign;
	    default :
		retract ();
		return Token.Remainder;
	    }
	}

	/*

	& &= && &&=

	*/

	function and ()
	    : int
	{
	    var c /*: int*/ = next ();
	    switch (c) {
	    case Char.Equal : return Token.BitwiseAndAssign;
	    case Char.Ampersand : return logicalAnd ();
	    default :
		retract ();
		return Token.BitwiseAnd;
	    }
	}

	function logicalAnd ()
	    : int
	{
	    var c /*: int*/ = next ();
	    switch (c) {
	    case Char.Equal : return Token.LogicalAndAssign;
	    default :
		retract ();
		return Token.LogicalAnd;
	    }
	}

	/*

	* *=

	*/

	function mult ()
	    : int
	{
	    var c /*: int*/ = next ();
	    switch (c) {
	    case Char.Equal : return Token.MultAssign;
	    default :
		retract ();
		return Token.Mult;
	    }
	}

	/*

	+ +==

	*/

	function plus ()
	    : int
	{
	    var c /*: int*/ = next ();
	    switch (c) {
	    case Char.Plus : return Token.PlusPlus;
	    case Char.Equal : return Token.PlusAssign;
	    default :
		retract ();
		return Token.Plus;
	    }
	}

	/*

	- -- -=

	*/

	function minus ()
	    : int
	{
	    var c /*: int*/ = next ();
	    switch (c) {
	    case Char.Dash : return Token.MinusMinus;
	    case Char.Equal : return Token.MinusAssign;
	    default :
		retract ();
		return Token.Minus;
	    }
	}

	/*

	/ /= />

	*/

	function div ()
	    : int
	{
	    var c /*: int*/ = next ();
	    switch (c) {
	    case Char.Equal : return Token.DivAssign;
	    case Char.RightAngle : return Token.XmlTagEndEnd;
	    default :
		retract ();
		return Token.Div;
	    }
	}

	/*

	< <= </ << <<=

	*/

	function leftAngle ()
	    : int
	{
	    var c /*: int*/ = next ();
	    switch (c) {
	    case Char.Equal : return Token.LessThanOrEqual;
	    case Char.LeftAngle : return leftShift ();
	    case Char.Slash : return Token.XmlTagStartEnd
	    default :
		retract ();
		return Token.LessThan;
	    }
	}

	function leftShift ()
	    : int
	{
	    var c /*: int*/ = next ();
	    switch (c) {
	    case Char.Equal : return Token.LeftShiftAssign;
	    default :
		retract ();
		return Token.LeftShift;
	    }
	}

	/*

	= == ===

	*/

	function equal ()
	    : int
	{
	    var c /*: int*/ = next ();
	    switch (c) {
	    case Char.Equal : return equalEqual ();
	    default :
		retract ();
		return Token.Assign;
	    }
	}

	function equalEqual ()
	    : int
	{
	    var c /*: int*/ = next ();
	    switch (c) {
	    case Char.Equal : return Token.StrictEqual;
	    default :
		retract ();
		return Token.Equal;
	    }
	}


	/*

	> >= >> >>= >>> >>>=

	*/

	function rightAngle ()
	    : int
	{
	    var c /*: int*/ = next ();
	    switch (c) {
	    case Char.Equal : return Token.GreaterThanOrEqual;
	    case Char.RightAngle : return rightShift ();
	    default :
		retract ();
		return Token.GreaterThan;
	    }
	}

	function rightShift ()
	    : int
	{
	    var c /*: int*/ = next ();
	    switch (c) {
	    case Char.Equal : return Token.RightShiftAssign;
	    case Char.RightAngle : return unsignedRightShift ();
	    default :
		retract ();
		return Token.RightShift;
	    }
	}

	function unsignedRightShift ()
	    : int
	{
	    var c /*: int*/ = next ();
	    switch (c) {
	    case Char.Equal : return Token.UnsignedRightShiftAssign;
	    default :
		retract ();
		return Token.UnsignedRightShift;
	    }
	}

	/*

	^ ^=

	*/

	function bitwiseXor ()
	    : int
	{
	    var c /*: int*/ = next ();
	    switch (c) {
	    case Char.Equal : return Token.BitwiseXorAssign;
	    default :
		retract ();
		return Token.BitwiseXor;
	    }
	}

	/*

	| |= || ||=

	*/

	function bitwiseOr ()
	    : int
	{
	    var c /*: int*/ = next ();
	    switch (c) {
	    case Char.Equal : return Token.BitwiseOrAssign;
	    case Char.Bar : return logicalOr ();
	    default :
		retract ();
		return Token.BitwiseOr;
	    }
	}

	function logicalOr ()
	    : int
	{
	    var c /*: int*/ = next ();
	    switch (c) {
	    case Char.Equal : return Token.LogicalOrAssign;
	    default :
		retract ();
		return Token.LogicalOr;
	    }
	}

	/*

	: ::

	*/

	function colon ()
	    : int
	{
	    var c /*: int*/ = next ();
	    switch (c) {
	    case Char.Colon : return Token.DoubleColon;
	    default :
		retract ();
		return Token.Colon;
	    }
	}

	/*

	identifier

	*/

        function identifier (str:String)
            : int
        {
            var c /*: int*/ = next ();
            //trace("c[",curIndex-1,"]=",String.fromCharCode(c))
            switch (c)
            {
            case Char.a :
            case Char.b :
            case Char.c :
            case Char.d :
            case Char.e :
            case Char.f :
            case Char.g :
            case Char.h :
            case Char.i :
            case Char.j :
            case Char.k :
            case Char.l :
            case Char.m :
            case Char.n :
            case Char.o :
            case Char.p :
            case Char.q :
            case Char.r :
            case Char.s :
            case Char.t :
            case Char.u :
            case Char.v :
            case Char.w :
            case Char.x :
            case Char.y :
            case Char.z :
            case Char.A :
            case Char.B :
            case Char.B :
            case Char.C :
            case Char.D :
            case Char.E :
            case Char.F :
            case Char.G :
            case Char.H :
            case Char.I :
            case Char.J :
            case Char.K :
            case Char.L :
            case Char.M :
            case Char.N :
            case Char.O :
            case Char.P :
            case Char.Q :
            case Char.R :
            case Char.S :
            case Char.T :
            case Char.U :
            case Char.V :
            case Char.W :
            case Char.X :
            case Char.Y :
            case Char.Z :
		return identifier (str+String.fromCharCode(c));
	    case Char.BackSlash:
		var c = escapeSequence ();
		return identifier (str+String.fromCharCode(c));
            default:
                if (Char.isIdentifierPart (c) && c != Char.EOS)
                {
                    return identifier (str+String.fromCharCode(c));
                }
                else
                {
                    retract ();
                    return Token.maybeReservedIdentifier (str);
                }
            }
        }

        function b_ () : int
        {
            var c /*: int*/ = next ();
            switch (c)
            {
                case Char.r:
		    return br_ ();
                default:
                    retract ();
                    return identifier ("b");
            }
        }

        function br_ ()
            : int
        {
            var c /*: int*/ = next ();
            switch (c)
            {
                case Char.e :
		    return identifier ("bre");
                default:
                    retract ();
                    return identifier ("br");
            }
        }

        function d_ ()
            : int
        {
            var c /*: int*/ = next ();
            switch (c)
            {
                case Char.e : return identifier ("de");
                default:
                    retract ();
                    return identifier ("d");
            }
        }

        function n_ ()
            : int
        {
            var c /*: int*/ = next();
            switch (c)
            {
                case Char.a : return identifier ("na");
                case Char.e : return identifier ("ne");
                case Char.u : return nu_ ();
                default:
                    retract ();
                    return identifier ("n");
            }
        }

        function nu_ ()
            : int
        {
            var c /*: int*/ = next ();
            switch (c) {
            case Char.l : return nul_ ();
            default:
                retract ();
                return identifier ("nu");
            }
        }

        function nul_ ()
            : int
        {
            var c /*: int*/ = next ();
            switch (c) {
            case Char.l : return null_ ();
            default:
                retract ();
                return identifier ("nul");
            }
        }

        function null_ ()
            : int
        {
            var c /*: int*/ = next ();
            if (Char.isIdentifierPart (c))
            {
                return identifier ("null"+String.fromCharCode(c));
            }
            else
            {
                retract();
                return Token.Null;
            }
        }
    }

}
	
import com.hurlant.eval.parse.Scanner;
import com.hurlant.eval.parse.Token;
	

function test()
{
    trace ("testing lex-scan.es");
    var testCases = [ "break case catch continue default delete do else enum extends"
                      , "false finally for function if in instanceof new null return"
                      , "super switch this throw true try typeof var void while with"
                      , "call cast const decimal double dynamic each eval final get has"
                      , "implements import int interface internal intrinsic is let namespace"
                      , "native Number override package precision private protected prototype public"
                      , "rounding standard strict static to type uint undefined use xml yield"
                      , ". .< .. ... ! != !== % %= & && &&= * *= + +- ++ - -- -="
                      , "/ /= /> < <= </ << <<= = == === > >= >> >>= >>> >>>="
                      , "^ ^= | |= || ||= : :: ( ) [ ] { } ~ @ , ; ?"
                      , "/* hello nobody */ hello // goodbye world"
                      , "0 0i 00 001u 0123d 045m 0x0 0xCAFEBABE 0x12345678u 1. .0 .2e+3 1.23m"
                      // , "\\u0050 \\x50gh \\073 \\73 \\073123 \\7398"
                      , "/abc/ 'hi' \"bye\" null break /def/xyz" ];

    for (var i = 0; i < testCases.length; ++i) {
        var scan = new Scanner (testCases[i],"test"+i);
        var tmp = scan.tokenList (scan.start);
        var tokens=tmp[0], coords=tmp[1]
        trace ("tokens ", tokens);
        trace ("coords ", coords);
        for (var j=0; j<tokens.length; ++j) {
        	if (tokens[j] == Token.BREAK) {
                if (i == testCases.length-1) {   // if last test, then scan for regexps
                    var tmp = scan.tokenList (scan.regexp);
			        var tokens=tmp[0], coords=tmp[1]
                }
                else {
                    var tmp = scan.tokenList (scan.div);
			        var tokens=tmp[0], coords=tmp[1]
                }
                trace ("tokens ", tokens);
                trace ("coords ", coords);
            }
        }
        trace ("scanned!");
    }
}

