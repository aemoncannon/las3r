package com.hurlant.eval.ast
{
	public class ProtectedNamespace implements IAstNamespace,IAstReservedNamespace {
        public var name : String
        function ProtectedNamespace (name) {
            this.name = name
        }
        function hash () { return "protected " + name; }
    }


}