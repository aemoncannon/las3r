package com.hurlant.eval.ast
{
    public class ArrayType implements IAstTypeExpr {
        public var types : Array;
        function ArrayType (types) {
            this.types = types;
        }
    }
}