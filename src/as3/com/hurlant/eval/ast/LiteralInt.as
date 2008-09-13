package com.hurlant.eval.ast
{
    public class LiteralInt implements IAstLiteral {
        public var intValue : int;
        function LiteralInt(intValue) { 
            this.intValue=intValue;
        }
    }
}