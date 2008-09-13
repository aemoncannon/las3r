package com.hurlant.eval.ast
{
    public class BinaryExpr implements IAstExpr {
        public var op : IAstBinOp
        public var e1 : IAstExpr
        public var e2 : IAstExpr
    	function BinaryExpr (op,e1,e2) {
	        this.op=op;
	        this.e1=e1;
	        this.e2=e2;
	    }
    }
}