package com.hurlant.eval.ast
{
    public class LiteralBoolean implements IAstLiteral {
        public var booleanValue : Boolean;
        function LiteralBoolean(booleanValue) { 
            this.booleanValue=booleanValue;
        }
    }
}