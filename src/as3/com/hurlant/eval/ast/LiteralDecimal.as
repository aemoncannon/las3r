package com.hurlant.eval.ast
{
    public class LiteralDecimal implements IAstLiteral {
        public var decimalValue : String;
        function LiteralDecimal (str : String) {
            this.decimalValue = str;  // FIXME: convert from string to decimal
        }
    }
}