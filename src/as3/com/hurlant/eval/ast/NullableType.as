package com.hurlant.eval.ast
{
    public class NullableType implements IAstTypeExpr {
        public var type : IAstTypeExpr;
        public var isNullable : Boolean;
        function NullableType (ty,isNullable) {
            this.type = ty;
            this.isNullable = isNullable;
        }
    }
}