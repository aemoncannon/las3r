package com.hurlant.eval.ast
{
    public class InitStep implements IAstInitStep {
        public var ident : IAstBindingIdent;
        public var expr : IAstExpr;
        function InitStep (ident,expr) {
            this.ident = ident;
            this.expr = expr;
        }
    }
}