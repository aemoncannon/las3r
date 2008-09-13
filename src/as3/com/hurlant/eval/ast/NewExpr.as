package com.hurlant.eval.ast
{
    public class NewExpr implements IAstExpr {
        public var expr : IAstExpr;
        public var args : Array;
        function NewExpr (expr,args) {
            this.expr = expr;
            this.args = args;
        }
    }
}