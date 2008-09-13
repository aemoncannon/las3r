package com.hurlant.eval.ast
{
    public class TypeIdentifier implements IAstIdentExpr {
        public var ident : IAstIdentExpr;
        public var typeArgs : [IAstTypeExpr];
        function TypeIdentifier (ident,typeArgs) {
            this.ident=ident;
            this.typeArgs=typeArgs;
        }
    }
}