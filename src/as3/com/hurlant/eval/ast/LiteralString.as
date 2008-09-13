package com.hurlant.eval.ast
{
    public class LiteralString implements IAstLiteral {
        public var strValue : String;
        function LiteralString (strValue) {
            this.strValue = strValue;
        }
    }
}