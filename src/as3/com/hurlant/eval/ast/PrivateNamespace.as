package com.hurlant.eval.ast
{
	public class PrivateNamespace implements IAstNamespace,IAstReservedNamespace {
        public var name : String
        function PrivateNamespace (name) {
            this.name = name;
        } 
        function hash () { return "private " + name; }
    }


}