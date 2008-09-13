package com.hurlant.eval.ast
{
    public class LabeledStmt implements IAstStmt {
        public var ident : String;
        public var stmt : IAstStmt;
        function LabeledStmt (label,stmt) {
            this.ident = ident;
            this.stmt = stmt;
        }
    }
}