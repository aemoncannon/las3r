package com.hurlant.eval.ast
{
    public class LetExpr implements IAstExpr {
        public var head : Head;
        public var expr : IAstExpr;
        function LetExpr (head,expr) {
            this.head = head;
            this.expr = expr;
        }
    }
}