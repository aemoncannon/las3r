package com.hurlant.eval.ast
{
    public class LiteralNamespace implements IAstLiteral {
        public var namespaceValue : IAstNamespace;
        function LiteralNamespace (namespaceValue) {
            this.namespaceValue = namespaceValue;
        }
    }
}