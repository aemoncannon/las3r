package com.hurlant.eval.ast
{
    public class ElementTypeRef implements IAstTypeExpr {
        public var base : IAstTypeExpr;
        public var index : int;
        function ElementTypeRef (base,index) {
            this.base = base;
            this.index = index;
        }
    }
}