package com.hurlant.eval.ast
{
    public class ObjectType implements IAstTypeExpr {
        public var fields : Array; //[FIELD_TYPE];
        function ObjectType (fields) {
            this.fields = fields;
        }
    }
}