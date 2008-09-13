package com.hurlant.eval.ast
{
    public class WithStmt implements IAstStmt {
        public var expr : IAstExpr;
        public var stmt : IAstStmt;
        function WithStmt (expr,stmt) {
            this.expr = expr;
            this.stmt = stmt;
        }
    }
}