package com.hurlant.eval.ast
{
    public class BinaryTypeExpr implements IAstExpr {
        public var op : IAstBinTypeOp
        public var e1 : IAstExpr
        public var e2 : IAstTypeExpr
	    function BinaryTypeExpr (op,e1,e2) {
	        this.op=op;
	        this.e1=e1;
	        this.e2=e2;
	    }
	}
}