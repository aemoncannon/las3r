package com.hurlant.eval.ast
{
    public class CallExpr implements IAstExpr {
        public var expr : IAstExpr;
        public var args : Array;
        function CallExpr (expr,args) {
            this.expr = expr;
            this.args = args;
        }
    }
}