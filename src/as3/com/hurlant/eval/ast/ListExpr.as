package com.hurlant.eval.ast
{
    public class ListExpr implements IAstExpr {
        public var exprs : Array;
        function ListExpr (exprs) { 
            this.exprs=exprs
    	}
    }
}