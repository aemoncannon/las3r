package com.hurlant.eval.ast
{
    public class LiteralContextHexInteger implements IAstLiteral {
        public var strValue : String;
        function LiteralContextHexInteger (strValue) {
            this.strValue=strValue;
        }
    }
}