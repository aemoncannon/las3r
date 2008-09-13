package com.hurlant.eval.ast
{
    public class PropIdent implements IAstBindingIdent {
        public var ident : String;
        function PropIdent (ident) {
            this.ident = ident;
        }
    }
}