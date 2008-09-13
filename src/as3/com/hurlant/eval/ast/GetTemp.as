package com.hurlant.eval.ast
{
    public class GetTemp implements IAstExpr {
        public var n : int;
        function GetTemp (n) {
            this.n = n;
        }
    }
}