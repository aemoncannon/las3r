package com.hurlant.eval.ast
{
    public class SuperExpr implements IAstExpr {
        public var ex : IAstExpr?;
        function SuperExpr (ex=null) {
            this.ex=ex; 
        }
    }
}