package com.hurlant.eval.ast
{
    public class ExprStmt implements IAstStmt {
        public var expr : IAstExpr;
        function ExprStmt (expr) {
            this.expr = expr;
        }
    }
}