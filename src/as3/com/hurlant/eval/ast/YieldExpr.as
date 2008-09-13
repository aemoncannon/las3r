package com.hurlant.eval.ast
{
    public class YieldExpr implements IAstExpr {
        public var ex : IAstExpr;
        function YieldExpr (ex=null) {
            this.ex=ex; 
        }
    }
}