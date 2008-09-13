package com.hurlant.eval.ast
{
    public class TypeExpr implements IAstExpr {
        public var ex : IAstTypeExpr;
        function TypeExpr (ex) {
            this.ex=ex;
        }
    }
}