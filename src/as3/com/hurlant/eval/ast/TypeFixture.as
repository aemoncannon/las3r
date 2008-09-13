package com.hurlant.eval.ast
{
    public class TypeFixture implements IAstFixture {
        public var type: IAstTypeExpr;
        function TypeFixture (ty) {
            this.type = ty;
        }
    }
}