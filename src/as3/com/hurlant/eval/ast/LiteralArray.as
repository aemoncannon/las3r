package com.hurlant.eval.ast
{
	public class LiteralArray implements IAstLiteral
	{
        public var exprs //: [IAstExpr];
        public var type : IAstTypeExpr;
		public function LiteralArray(exprs,ty) {
            this.exprs = exprs;
            this.type = ty;
		}
	}
}