package com.hurlant.eval.ast
{
    public class Case {
        public var expr : IAstExpr?;  // null for default
        public var stmts : Array; //STMTS;
        function Case (expr,stmts) {
            this.expr = expr;
            this.stmts = stmts;
        }
    }
}