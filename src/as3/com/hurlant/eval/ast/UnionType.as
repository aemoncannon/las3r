package com.hurlant.eval.ast
{
    public class UnionType implements IAstTypeExpr {
        public var types : Array //[IAstTypeExpr];
        function UnionType (types) {
            this.types = types;
        }
    }
}