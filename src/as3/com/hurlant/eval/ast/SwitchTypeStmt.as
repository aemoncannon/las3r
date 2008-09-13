package com.hurlant.eval.ast
{
    public class SwitchTypeStmt implements IAstStmt {
        public var expr: IAstExpr;
        public var type: IAstTypeExpr;
        public var cases: Array; //CATCHES;
        function SwitchTypeStmt (expr,ty,cases) {
            this.expr = expr;
            this.type = ty;
            this.cases = cases;
        }
    }
}