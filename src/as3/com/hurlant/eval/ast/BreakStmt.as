package com.hurlant.eval.ast
{
    public class BreakStmt implements IAstStmt {
        public var ident : String?;
        function BreakStmt (ident) {
            this.ident = ident;
        }
    }
}