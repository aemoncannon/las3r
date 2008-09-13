package com.hurlant.eval.ast
{
    public class ValFixture implements IAstFixture {
        public var type : IAstTypeExpr;
        public var isReadOnly : Boolean;
        function ValFixture(ty, isReadOnly) {
        	this.type=ty;
        	this.isReadOnly=isReadOnly;
        }
    }
}