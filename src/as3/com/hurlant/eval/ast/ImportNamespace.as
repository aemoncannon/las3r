package com.hurlant.eval.ast
{
	public class ImportNamespace implements IAstNamespace {
        public var ident : String
        public var ns : PublicNamespace
        function hash () { return "import " + ns.hash; }
    }


}