package com.hurlant.eval.ast
{
    public class SwitchStmt implements IAstStmt {
        public var expr : IAstExpr;
        public var cases : Array; //CASES;
        public var labels : Array; //[String];
        function SwitchStmt (expr, cases, labels) {
            this.expr = expr;
            this.cases = cases;
            this.labels = labels;
        }
    }
}