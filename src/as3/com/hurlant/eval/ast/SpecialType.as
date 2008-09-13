package com.hurlant.eval.ast
{
    public class SpecialType implements IAstTypeExpr {
        public var kind : IAstSpecialTypeKind;
        function SpecialType(kind) { 
        	this.kind=kind;
        }
    }
}