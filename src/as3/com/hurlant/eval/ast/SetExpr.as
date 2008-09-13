package com.hurlant.eval.ast
{
    public class SetExpr implements IAstExpr {
        public var op : IAstAssignOp;
        public var le : IAstExpr;
        public var re : IAstExpr;
        function SetExpr (op,le,re) {
            this.op=op;
            this.le=le;
            this.re=re;
        }
    }
}