package com.hurlant.eval.ast
{
	public    class PublicNamespace implements IAstNamespace,IAstReservedNamespace {
        public var name : String;
        function PublicNamespace (name) {
            this.name = name
        }
        function hash () { return "public " + name; }
    }


}