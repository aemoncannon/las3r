package com.hurlant.eval.parse
{
	public class Token
	{
	
	    public static const firstTokenClass = -1
	    public static const Minus = firstTokenClass
	    public static const MinusMinus = Minus - 1
	    public static const Not = MinusMinus - 1
	    public static const NotEqual = Not - 1
	    public static const StrictNotEqual = NotEqual - 1
	    public static const Remainder = StrictNotEqual - 1
	    public static const RemainderAssign = Remainder - 1
	    public static const BitwiseAnd = RemainderAssign - 1
	    public static const LogicalAnd = BitwiseAnd - 1
	    public static const LogicalAndAssign = LogicalAnd - 1
	    public static const BitwiseAndAssign = LogicalAndAssign - 1
	    public static const LeftParen = BitwiseAndAssign - 1
	    public static const RightParen = LeftParen - 1
	    public static const Mult = RightParen - 1
	    public static const MultAssign = Mult - 1
	    public static const Comma = MultAssign  - 1
	    public static const Dot = Comma - 1
	    public static const DoubleDot = Dot - 1
	    public static const TripleDot = DoubleDot - 1
	    public static const LeftDotAngle = TripleDot - 1
	    public static const Div = LeftDotAngle - 1
	    public static const DivAssign = Div - 1
	    public static const Colon = DivAssign - 1
	    public static const DoubleColon = Colon - 1
	    public static const SemiColon = DoubleColon - 1
	    public static const QuestionMark = SemiColon - 1
	    public static const At = QuestionMark - 1
	    public static const LeftBracket = At - 1
	    public static const RightBracket = LeftBracket - 1
	    public static const LogicalXor = RightBracket - 1
	    public static const LogicalXorAssign = LogicalXor - 1
	    public static const LeftBrace = LogicalXorAssign - 1
	    public static const LogicalOr = LeftBrace - 1
	    public static const LogicalOrAssign = LogicalOr - 1
	    public static const BitwiseOr = LogicalOrAssign - 1
	    public static const BitwiseOrAssign = BitwiseOr - 1
	    public static const BitwiseXor = BitwiseOrAssign - 1
	    public static const BitwiseXorAssign = BitwiseXor - 1
	    public static const RightBrace = BitwiseXorAssign - 1
	    public static const BitwiseNot = RightBrace - 1
	    public static const Plus = BitwiseNot - 1
	    public static const PlusPlus = Plus - 1
	    public static const PlusAssign = PlusPlus - 1
	    public static const LessThan = PlusAssign - 1
	    public static const LeftShift = LessThan - 1
	    public static const LeftShiftAssign = LeftShift - 1
	    public static const LessThanOrEqual = LeftShiftAssign - 1
	    public static const Assign = LessThanOrEqual - 1
	    public static const MinusAssign = Assign - 1
	    public static const Equal = MinusAssign - 1
	    public static const StrictEqual = Equal - 1
	    public static const GreaterThan = StrictEqual - 1
	    public static const GreaterThanOrEqual = GreaterThan - 1
	    public static const RightShift = GreaterThanOrEqual - 1
	    public static const RightShiftAssign = RightShift - 1
	    public static const UnsignedRightShift = RightShiftAssign - 1
	    public static const UnsignedRightShiftAssign = UnsignedRightShift - 1
	
	    /* reserved identifiers */
	
	    public static const Break = UnsignedRightShiftAssign - 1
	    public static const Case = Break - 1
	    public static const Catch = Case - 1
	    public static const Class = Catch - 1
	    public static const Continue = Class - 1
	    public static const Default = Continue - 1
	    public static const Delete = Default - 1
	    public static const Do = Delete - 1
	    public static const Else = Do - 1
	    public static const Enum = Else - 1
	    public static const Extends = Enum - 1
	    public static const False = Extends - 1
	    public static const Finally = False - 1
	    public static const For = Finally - 1
	    public static const Function = For - 1
	    public static const If = Function - 1
	    public static const In = If - 1
	    public static const InstanceOf = In - 1
	    public static const New = InstanceOf - 1
	    public static const Null = New - 1
	    public static const Return = Null - 1
	    public static const Super = Return - 1
	    public static const Switch = Super - 1
	    public static const This = Switch - 1
	    public static const Throw = This - 1
	    public static const True = Throw - 1
	    public static const Try = True - 1
	    public static const TypeOf = Try - 1
	    public static const Var = TypeOf - 1
	    public static const Void = Var - 1
	    public static const While = Void - 1
	    public static const With = While - 1
	
	    /* contextually reserved identifiers */
	
	    public static const Call = With - 1
	    public static const Cast = Call - 1
	    public static const Const = Cast - 1
	    public static const Decimal = Const - 1
	    public static const Double = Decimal - 1
	    public static const Dynamic = Double - 1
	    public static const Each = Dynamic - 1
	    public static const Eval = Each - 1
	    public static const Final = Eval - 1
	    public static const Get = Final - 1
	    public static const Has = Get - 1
	    public static const Implements = Has - 1
	    public static const Import = Implements - 1
	    public static const Int = Import - 1
	    public static const Interface = Int - 1
	    public static const Internal = Interface - 1
	    public static const Intrinsic = Internal - 1
	    public static const Is = Intrinsic - 1
	    public static const Let = Is - 1
	    public static const Namespace = Let - 1
	    public static const Native = Namespace - 1
	    public static const Number = Native - 1
	    public static const Override = Number - 1
	    public static const Package = Override - 1
	    public static const Precision = Package - 1
	    public static const Private = Precision - 1
	    public static const Protected = Private - 1
	    public static const Prototype = Protected - 1
	    public static const Public = Prototype - 1
	    public static const Rounding = Public - 1
	    public static const Standard = Rounding - 1
	    public static const Strict = Standard - 1
	    public static const To = Strict - 1
	    public static const Set = To - 1
	    public static const Static = Set - 1
	    public static const Type = Static - 1
	    public static const UInt = Type - 1
	    public static const Undefined = UInt - 1
	    public static const Unit = Undefined - 1
	    public static const Use = Unit - 1
	    public static const Xml = Use - 1
	    public static const Yield = Xml - 1
	
	    /* literals */
	
	    public static const AttributeIdentifier = Yield - 1
	    public static const BlockComment = AttributeIdentifier - 1
	    public static const DocComment = BlockComment - 1
	    public static const Eol = DocComment - 1
	    public static const Identifier = Eol - 1
	
	    // The interpretation of these 4 literal types can be done during lexing
	
	    public static const ExplicitDecimalLiteral = Identifier - 1
	    public static const ExplicitDoubleLiteral = ExplicitDecimalLiteral - 1
	    public static const ExplicitIntLiteral = ExplicitDoubleLiteral - 1
	    public static const ExplicitUIntLiteral = ExplicitIntLiteral - 1
	
	    // The interpretation of these 3 literal types is deferred until defn phase
	
	    public static const DecimalIntegerLiteral = ExplicitUIntLiteral - 1
	    public static const DecimalLiteral = DecimalIntegerLiteral - 1
	    public static const HexIntegerLiteral = DecimalLiteral - 1
	
	    public static const RegexpLiteral = HexIntegerLiteral - 1
	    public static const SlashSlashComment = RegexpLiteral - 1
	    public static const StringLiteral = SlashSlashComment - 1
	    public static const Space = StringLiteral - 1
	    public static const XmlLiteral = Space - 1
	    public static const XmlPart = XmlLiteral - 1
	    public static const XmlMarkup = XmlPart - 1
	    public static const XmlText = XmlMarkup - 1
	    public static const XmlTagEndEnd = XmlText - 1
	    public static const XmlTagStartEnd = XmlTagEndEnd - 1
	
	    // meta
	
	    public static const ERROR = XmlTagStartEnd - 1
	    public static const EOS = ERROR - 1
	    public static const BREAK = EOS - 1
	    public static const lastTokenClass = BREAK
	
	    public static const names = [
	        "<unused index>",
	        "minus",
	        "minusminus",
	        "not",
	        "notequals",
	        "strictnotequals",
	        "modulus",
	        "modulusassign",
	        "bitwiseand",
	        "logicaland",
	        "logicalandassign",
	        "bitwiseandassign",
	        "leftparen",
	        "rightparen",
	        "mult",
	        "multassign",
	        "comma",
	        "dot",
	        "doubledot",
	        "tripledot",
	        "leftdotangle",
	        "div",
	        "divassign",
	        "colon",
	        "doublecolon",
	        "semicolon",
	        "questionmark",
	        "at",
	        "leftbracket",
	        "rightbracket",
	        "logicalxor",
	        "logicalxorassign",
	        "leftbrace",
	        "logicalor",
	        "logicalorassign",
	        "bitwiseor",
	        "bitwiseorassign",
	        "bitwisexor",
	        "bitwisexorassign",
	        "rightbrace",
	        "bitwisenot",
	        "plus",
	        "plusplus",
	        "plusassign",
	        "lessthan",
	        "leftshift",
	        "leftshiftassign",
	        "lessthanorequals",
	        "assign",
	        "minusassign",
	        "equals",
	        "strictequals",
	        "greaterthan",
	        "greaterthanorequals",
	        "rightshift",
	        "rightshiftassign",
	        "unsignedrightshift",
	        "unsignedrightshiftassign",
	        "break",
	        "case",
	        "catch",
	        "class",
	        "continue",
	        "default",
	        "delete",
	        "do",
	        "else",
	        "enum",
	        "extends",
	        "false",
	        "finally",
	        "for",
	        "function",
	        "if",
	        "in",
	        "instanceof",
	        "new",
	        "null",
	        "return",
	        "super",
	        "switch",
	        "this",
	        "throw",
	        "true",
	        "try",
	        "typeof",
	        "var",
	        "void",
	        "while",
	        "with",
	
	        "call",
	        "cast",
	        "const",
	        "decimal",
	        "double",
	        "dynamic",
	        "each",
	        "eval",
	        "final",
	        "get",
	        "has",
	        "implements",
	        "import",
	        "int",
	        "interface",
	        "internal",
	        "intrinsic",
	        "is",
	        "let",
	        "namespace",
	        "native",
	        "Number",
	        "override",
	        "package",
	        "precision",
	        "private",
	        "protected",
	        "prototype",
	        "public",
	        "rounding",
	        "standard",
	        "strict",
	        "to",
	        "set",
	        "static",
	        "type",
	        "uint",
	        "undefined",
	        "unit",
	        "use",
	        "xml",
	        "yield",
	
	        "attributeidentifier",
	        "blockcomment",
	        "doccomment",
	        "eol",
	        "identifier",
	        "explicitdecimalliteral",
	        "explicitdoubleliteral",
	        "explicitintliteral",
	        "explicituintliteral",
	        "decimalintegerliteral",
	        "decimalliteral",
	        "hexintegerliteral",
	        "regexpliteral",
	        "linecomment",
	        "stringliteral",
	        "space",
	        "xmlliteral",
	        "xmlpart",
	        "xmlmarkup",
	        "xmltext",
	        "xmltagendend",
	        "xmltagstartend",
	
	        "ERROR",
	        "EOS",
	        "BREAK"
	    ];

		
		public static const tokenStore = new Array;
		
		public static function maybeReservedIdentifier (lexeme:String) : int
		{
		    // ("maybeReservedIdentifier lexeme=",lexeme);
		    switch (lexeme) {
		
		    // ContextuallyReservedIdentifiers
		
		    case "break": return Token.Break;
		    case "case": return Token.Case;
		    case "catch": return Token.Catch;
		    case "class": return Token.Class;
		    case "continue": return Token.Continue;
		    case "default": return Token.Default;
		    case "delete": return Token.Delete;
		    case "do": return Token.Do;
		    case "else": return Token.Else;
		    case "enum": return Token.Enum;
		    case "extends": return Token.Extends;
		    case "false": return Token.False;
		    case "finally": return Token.Finally;
		    case "for": return Token.For;
		    case "function": return Token.Function;
		    case "if": return Token.If;
		    case "in": return Token.In;
		    case "instanceof": return Token.InstanceOf;
		    case "new": return Token.New;
		    case "null": return Token.Null;
		    case "return": return Token.Return;
		    case "super": return Token.Super;
		    case "switch": return Token.Switch;
		    case "this": return Token.This;
		    case "throw": return Token.Throw;
		    case "true": return Token.True;
		    case "try": return Token.Try;
		    case "typeof": return Token.TypeOf;
		    case "var": return Token.Var;
		    case "void": return Token.Void;
		    case "while": return Token.While;
		    case "with": return Token.With;
		
		    // ContextuallyReservedIdentifiers
		
		    case "call": return Token.Call;
		    case "cast": return Token.Cast;
		    case "const": return Token.Const;
		    case "decimal": return Token.Decimal;
		    case "double": return Token.Double;
		    case "dynamic": return Token.Dynamic;
		    case "each": return Token.Each;
		    case "eval": return Token.Eval;
		    case "final": return Token.Final;
		    case "get": return Token.Get;
		    case "has": return Token.Has;
		    case "implements": return Token.Implements;
		    case "import": return Token.Import;
		    case "int": return Token.Int;
		    case "interface" : return Token.Interface;
		    case "internal": return Token.Internal;
		    case "intrinsic": return Token.Intrinsic;
		    case "is": return Token.Is;
		    case "let": return Token.Let;
		    case "namespace": return Token.Namespace;
		    case "native": return Token.Native;
		    case "Number": return Token.Number;
		    case "override": return Token.Override;
		    case "package": return Token.Package;
		    case "precision": return Token.Precision;
		    case "private": return Token.Private;
		    case "protected": return Token.Protected;
		    case "prototype": return Token.Prototype;
		    case "public": return Token.Public;
		    case "rounding": return Token.Rounding;
		    case "standard": return Token.Standard;
		    case "strict": return Token.Strict;
		    case "to": return Token.To;
		    case "set": return Token.Set;
		    case "static": return Token.Static;
		    case "to": return Token.To;
		    case "type": return Token.Type;
		    case "uint": return Token.UInt;
		    case "undefined": return Token.Undefined;
		    case "use": return Token.Use;
		    case "unit": return Token.Unit;
		    case "xml": return Token.Xml;
		    case "yield": return Token.Yield;
		    default: return Token.makeInstance (Token.Identifier,lexeme);
		    }
		}



		public static function makeInstance(kind:int, text:String) : int
		{
		    function find() {
		        for ( var i=0 ; i < len ; i++ ) {
		            if (tokenStore[i].kind === kind &&
		                tokenStore[i].utf8id == text) {
		                return i;
		            }
		        }
		        return len;
		    }
		
		    var len = tokenStore.length;
		    var tid = find ();
		    if (tid === len) 
		    {
		        tokenStore.push(new Tok(kind, text));
		    }
		    return tid;
		}

		public static function tokenKind (tid : int) : int
		{
		    // if the token id is negative, it is a token_class
		
		    //print("tid=",tid);
		    if (tid < 0)
		    {
		       return tid;
		    }
		
		    // otherwise, get instance data from the instance vector.
		
		    var tok : Tok = tokenStore[tid];
		    return tok.kind;
		}

		public static function tokenText ( tid : int ) : String
		{
		    if (tid < 0) {
		        // if the token id is negative, it is a token_class.
		        var text = Token.names[-tid];
		    }
		    else {
		        // otherwise, get instance data from the instance vector
		        var tok : Tok = tokenStore[tid];
		        var text = tok.tokenText();
		    }
		    //print("tokenText: ",tid,", ",text);
		    return text;
		}

	}
}

import com.hurlant.eval.parse.Token;

class Tok
{
    var kind;
    var utf8id;
    function Tok(kind,utf8id) {
        this.kind = kind;
        this.utf8id = utf8id;
    }

    function tokenText () : String
    {
        if (kind===Token.StringLiteral) {
            return this.utf8id.slice(1,this.utf8id.length);
        }
        return this.utf8id;
    }

    function tokenKind () : int
    {
        return this.kind;
    }
}
function test ()
{
    //print ("testing lex-token.es");
    for( var i = Token.firstTokenClass; i >= Token.lastTokenClass; --i )
        trace(i,": ",Token.names[-i])
}
	
