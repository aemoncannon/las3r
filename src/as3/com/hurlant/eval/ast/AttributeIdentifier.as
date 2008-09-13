package com.hurlant.eval.ast
{
    public class AttributeIdentifier implements IAstIdentExpr {
        public var ident : IAstIdentExpr;
        function AttributeIdentifier (ident) {
            this.ident=ident;
        }
    }
}