package com.hurlant.eval.ast
{
    public class QualifiedExpression implements IAstIdentExpr {
        public var qual : IAstExpr;
        public var expr : IAstExpr;
        function QualifiedExpression (qual,expr) {
            this.qual=qual;
            this.expr=expr;
        }
    }
}