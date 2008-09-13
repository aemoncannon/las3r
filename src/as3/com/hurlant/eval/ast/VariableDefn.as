package com.hurlant.eval.ast
{
    public class VariableDefn {
        public var ns: IAstNamespace;
        public var isStatic: Boolean;
        public var isPrototype: Boolean;
        public var kind: IAstVarDefnTag ;
        public var bindings: Array; //BINDING_INITS;
        function VariableDefn (ns,isStatic,isPrototype,kind,bindings) {
            this.ns = ns;
            this.isStatic = isStatic;
            this.isPrototype = isPrototype;
            this.kind = kind;
            this.bindings = bindings;
        }
    }
}