package com.hurlant.eval.ast
{
    public class ExpressionIdentifier implements IAstIdentExpr {
        public var expr: IAstExpr;
        public var nss //: [IAstNamespace];
        function ExpressionIdentifier (expr,nss) {
            this.expr=expr;
            this.nss = nss;
        }
    }
}