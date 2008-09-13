package com.hurlant.eval.ast
{
    public class Binding {
        public var ident : IAstBindingIdent;
        public var type : IAstTypeExpr?;
        function Binding (ident,ty) { // FIXME 'type' not allowed as param name in the RI
            this.ident = ident;
            this.type = ty;
        }
    }
}