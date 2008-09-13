package com.hurlant.eval.ast
{
	public    class UserNamespace implements IAstNamespace {
        public var name : String;
        function UserNamespace (name) {
            this.name = name
        }
        function hash () { return "use " + name; }
    }


}