package com.hurlant.eval.ast
{
    public class GetParam implements IAstExpr {
        public var n : int;
        function GetParam (n) { 
            this.n = n
        }
    }
}