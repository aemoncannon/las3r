package com.hurlant.eval.ast
{
    public class WhileStmt implements IAstStmt {
        public var expr : IAstExpr;
        public var stmt : IAstStmt;
        public var labels : Array; //[String];
        function WhileStmt (expr,stmt,labels) {
            this.expr = expr;
            this.stmt = stmt;
            this.labels = labels;
        }
    }
}