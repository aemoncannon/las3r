package com.hurlant.eval.ast
{
    public class ContinueStmt implements IAstStmt {
        public var ident : String?;
        function ContinueStmt (ident) {
            this.ident = ident;
        }
    }
}