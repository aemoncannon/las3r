package com.hurlant.eval.ast
{
	public class InternalNamespace implements IAstNamespace,IAstReservedNamespace {
        public var name : String;
        function InternalNamespace (name) {
            this.name = name
        }
        function hash () { return "internal " + name; }
    }

}