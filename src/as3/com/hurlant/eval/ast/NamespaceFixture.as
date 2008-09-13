package com.hurlant.eval.ast
{
    public class NamespaceFixture implements IAstFixture {
        public var ns : IAstNamespace;
        function NamespaceFixture (ns) {
            this.ns = ns;
        }
    }
}