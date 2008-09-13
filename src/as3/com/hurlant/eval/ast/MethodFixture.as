package com.hurlant.eval.ast
{
    public class MethodFixture implements IAstFixture {
        public var func : Func;
        public var type : IAstTypeExpr;
        public var isReadOnly : Boolean;
        public var isOverride : Boolean;
        public var isFinal : Boolean;
        function MethodFixture(func, ty, isReadOnly, isOverride, isFinal) {
            this.func = func;
            this.type = ty;
            this.isReadOnly = isReadOnly;
            this.isOverride = isOverride;
            this.isFinal = isFinal;
        }
    }
}