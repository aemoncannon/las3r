package com.hurlant.eval.ast
{
    public class ThrowStmt implements IAstStmt {
        public var expr : IAstExpr;
        function ThrowStmt (expr) {
            this.expr = expr;
        }
    }
}