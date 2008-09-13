package com.hurlant.eval.ast
{
    public class QualifiedIdentifier implements IAstIdentExpr {
        public var qual : IAstExpr;
        public var ident : String;
        function QualifiedIdentifier (qual,ident) {
            this.qual=qual;
            this.ident=ident;
        }
    }
}