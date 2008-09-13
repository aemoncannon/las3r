package com.hurlant.eval.ast
{
    public class UnaryExpr implements IAstExpr {
        public var op : IAstUnaryOp;
        public var e1 : IAstExpr;
	    function UnaryExpr (op,e1) {
            this.op=op;
            this.e1=e1;
         }
    }
}