package com.hurlant.eval.ast
{
	public class TernaryExpr implements IAstExpr {
        public var e1 : IAstExpr
        public var e2 : IAstExpr
        public var e3 : IAstExpr
    	function TernaryExpr (e1,e2,e3) {
            this.e1=e1;
            this.e2=e2;
            this.e3=e3;
        }
    }
}