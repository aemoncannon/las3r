package com.hurlant.eval.ast
{
    public class Identifier implements IAstIdentExpr {
        public var ident : String;
        public var nss //: NAMESPACES;
        function Identifier (ident,nss) {
            this.ident = ident;
            this.nss = nss;
        }
    }
}