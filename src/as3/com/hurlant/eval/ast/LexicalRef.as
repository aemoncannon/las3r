package com.hurlant.eval.ast
{
	public class LexicalRef implements IAstExpr
	{
        public var ident : IAstIdentExpr;
		public function LexicalRef(ident) {
            this.ident = ident;
		}

	}
}