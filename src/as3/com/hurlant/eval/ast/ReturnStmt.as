package com.hurlant.eval.ast
{
    public class ReturnStmt implements IAstStmt {
        public var expr : IAstExpr?;
        function ReturnStmt(expr) { 
            this.expr = expr;
        }
    }
}