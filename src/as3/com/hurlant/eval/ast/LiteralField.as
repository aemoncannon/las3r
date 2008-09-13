package com.hurlant.eval.ast
{
	public class LiteralField
	{
        public var kind: IAstVarDefnTag ;
        public var ident: IAstIdentExpr;
        public var expr: IAstExpr;
        
		public function LiteralField(kind,ident,expr) {
            this.kind = kind;
            this.ident = ident;
            this.expr = expr;
		}

	}
}