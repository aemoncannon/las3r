package com.hurlant.eval.ast
{
    public class ObjectRef implements IAstExpr {
        public var base : IAstExpr;
        public var ident : IAstIdentExpr;
        public var pos : Pos;
        function ObjectRef (base, ident, pos=null) {
            this.base = base;
            this.ident = ident;
            this.pos = pos;
    	}
    }
}