package com.hurlant.eval.ast
{
    public class LiteralContextDecimalInteger implements IAstLiteral {
        public var strValue : String;
        function LiteralContextDecimalInteger (strValue) {
            this.strValue=strValue;
        }
    }
}