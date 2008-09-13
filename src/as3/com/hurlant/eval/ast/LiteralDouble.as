package com.hurlant.eval.ast
{
    public class LiteralDouble implements IAstLiteral {
        public var doubleValue : Number;
        function LiteralDouble (doubleValue) {
            this.doubleValue=doubleValue;
        }
    }
}