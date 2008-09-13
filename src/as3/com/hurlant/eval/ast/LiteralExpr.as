package com.hurlant.eval.ast
{
	public class LiteralExpr implements IAstExpr
	{
        public var literal : IAstLiteral;
		public function LiteralExpr(literal) {
            this.literal = literal;
		}
	}
}