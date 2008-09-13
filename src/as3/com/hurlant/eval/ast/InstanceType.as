package com.hurlant.eval.ast
{
    public class InstanceType implements IAstTypeExpr {
        public var name : NAME;
        public var typeParams : Array; //[String];
        public var type : IAstTypeExpr;
        public var isDynamic : Boolean;
    }
}