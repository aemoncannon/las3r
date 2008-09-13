package com.hurlant.eval.ast
{
	public    class AnonymousNamespace implements IAstNamespace {
        public var name : String;
        function AnonymousNamespace (name) {
            this.name = name
        }
        function hash () { return "anon " + name; }
    }


}