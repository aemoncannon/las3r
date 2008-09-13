package com.hurlant.eval.ast
{
    public class FieldType {
        public var ident: String;
        public var type: IAstTypeExpr;
        function FieldType (ident,ty) {
            this.ident = ident;
            this.type = ty;
        }
    }
}