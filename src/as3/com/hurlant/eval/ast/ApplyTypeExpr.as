package com.hurlant.eval.ast
{
    public class ApplyTypeExpr implements IAstExpr {
        public var expr : IAstExpr;
        public var args : Array; //[IAstTypeExpr];
        function ApplyTypeExpr (expr,args) {
            this.expr = expr;
            this.args = args;
        }
    }
}