package com.hurlant.eval.ast
{
	public class Ast
	{
		
	    public static var noNS = new PublicNamespace ("");   // FIXME find better way to express
			
	    public static var castOp = new CastOp;
	    public static var isOp = new IsOp;
	    public static var toOp = new ToOp;
	
	    public static var plusOp = new Plus;
	    public static var minusOp = new Minus;
	    public static var timesOp = new Times;
	    public static var divideOp = new Divide;
	    public static var remainderOp = new Remainder;
	    public static var leftShiftOp = new LeftShift;
	    public static var rightShiftOp = new RightShift;
	    public static var rightShiftUnsignedOp = new RightShiftUnsigned;
	    public static var bitwiseAndOp = new BitwiseAnd;
	    public static var bitwiseOrOp = new BitwiseOr;
	    public static var bitwiseXorOp = new BitwiseXor;
	    public static var logicalAndOp = new LogicalAnd;
	    public static var logicalOrOp = new LogicalOr;
	    public static var logicalXorOp = new LogicalXor;
	    public static var instanceOfOp = new InstanceOf;
	    public static var inOp = new In;
	    public static var equalOp = new Equal;
	    public static var notEqualOp = new NotEqual;
	    public static var strictEqualOp = new StrictEqual;
	    public static var strictNotEqualOp = new StrictNotEqual;
	    public static var lessOp = new Less;
	    public static var lessOrEqualOp = new LessOrEqual;
	    public static var greaterOp = new Greater;
	    public static var greaterOrEqualOp = new GreaterOrEqual;
	
	    public static var assignOp = new Assign;
	
	    public static var deleteOp = new Delete;
	    public static var voidOp = new Void;
	    public static var typeOfOp = new Typeof;
	    public static var preIncrOp = new PreIncr;
	    public static var preDecrOp = new PreDecr;
	    public static var postIncrOp = new PostIncr;
	    public static var postDecrOp = new PostDecr;
	    public static var unaryPlusOp = new UnaryPlus;
	    public static var unaryMinusOp = new UnaryMinus;
	    public static var bitwiseNotOp = new BitwiseNot;
	    public static var logicalNotOp = new LogicalNot;
	    public static var typeOp = new Type;
	
	    public static var varInit = new VarInit;
	    public static var letInit = new LetInit;
	    public static var prototypeInit = new PrototypeInit;
	    public static var instanceInit = new InstanceInit;
	
	    public static var constTag = new Const;
	    public static var varTag = new Var;
	    public static var letVarTag = new LetVar;
	    public static var letConstTag = new LetConst;
	
	    public static var anyType = new SpecialType (new AnyType);
	    public static var nullType = new SpecialType (new NullType);
	    public static var undefinedType = new SpecialType (new UndefinedType);
	    public static var voidType = new SpecialType (new VoidType);
	

	}
}