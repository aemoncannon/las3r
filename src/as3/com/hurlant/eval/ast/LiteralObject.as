package com.hurlant.eval.ast
{
    public class LiteralObject implements IAstLiteral {
        public var fields : Array;
        public var type : IAstTypeExpr;
        function LiteralObject (fields, ty) {
            this.fields = fields;
            this.type = ty;
        }
    }
}