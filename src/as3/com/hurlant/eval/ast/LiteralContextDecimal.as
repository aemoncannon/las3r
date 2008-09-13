package com.hurlant.eval.ast
{
    public class LiteralContextDecimal implements IAstLiteral {
        public var strValue : String;
        function LiteralContextDecimal (strValue) {
            this.strValue=strValue;
        }
    }
}