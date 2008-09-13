package com.hurlant.eval.ast
{
    public class DoWhileStmt implements IAstStmt {
        public var expr : IAstExpr;
        public var stmt : IAstStmt;
        public var labels : Array; //[String];
        function DoWhileStmt (expr,stmt,labels) {
            this.expr = expr;
            this.stmt = stmt;
            this.labels = labels;
        }
    }
}