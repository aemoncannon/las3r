package com.hurlant.eval.ast
{
    public class ForStmt implements IAstStmt {
        public var vars : Head;
        public var init : IAstExpr?;
        public var cond : IAstExpr?;
        public var incr : IAstExpr?;
        public var stmt : IAstStmt;
        public var labels : Array; //[String];
        function ForStmt (vars,init,cond,incr,stmt,labels) {
            this.vars = vars;
            this.init = init;
            this.cond = cond;
            this.incr = incr;
            this.stmt = stmt;
            this.labels = labels;
        }
    }
}