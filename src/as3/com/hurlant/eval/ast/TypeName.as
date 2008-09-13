package com.hurlant.eval.ast
{
    public class TypeName implements IAstTypeExpr {
        public var ident : IAstIdentExpr;
        function TypeName (ident) {
            this.ident = ident;
        }
    }
}