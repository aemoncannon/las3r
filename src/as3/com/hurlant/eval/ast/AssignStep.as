package com.hurlant.eval.ast
{
    public class AssignStep implements IAstInitStep {
        public var le : IAstExpr;
        public var re : IAstExpr;
        function AssignStep (le,re) {
            this.le = le;
            this.re = re;
        }
    }
}