package com.hurlant.eval.ast
{
    public class FieldTypeRef implements IAstTypeExpr {
        var base : IAstTypeExpr;
        var ident : IAstIdentExpr;
        function FieldTypeRef (base,ident) {
            this.base = base;
            this.ident = ident;
        }
    }
}