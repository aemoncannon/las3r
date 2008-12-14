package com.hurlant.eval.gen
{
	import com.hurlant.eval.Util;
	import com.hurlant.eval.abc.ABCConstantPool;
	import com.hurlant.eval.abc.ABCFile;
	
	public class ABCEmitter
	{
        public var file:ABCFile, constants:ABCConstantPool;
        private var scripts:Array = [];

        function ABCEmitter() {
            file = new ABCFile;
            constants = new ABCConstantPool;
            file.addConstants(constants);
        }

        public function newScript(): Script {
            var s:Script = new Script(this);
            scripts.push(s);
            return s;
        }

        public function finalize():ABCFile {
            Util.forEach(function(s):void { s.finalize(); }, scripts);
            return file;
        }

		
        public var meta_construct_name;

        public function namespace( ns:String ):int {
			return constants.namespace(AVM2Assembler.CONSTANT_Namespace, constants.stringUtf8(ns));
        }

        public function flattenNamespaceSet(nss:Array /*:[[NAMESPACE]]*/) {
            var new_nss:Array = [];
            for( var i:int = 0; i < nss.length; i++ ) {
                var temp = nss[i];
                for( var q = 0; q < temp.length; q++) {
                    new_nss.push(namespace(temp[q]));
                } 
            } 
            return new_nss;
        }
        public function multiname(mname, is_attr) {
            //var {nss:nss, ident:ident} = mname;
            var nss=mname.nss, ident=mname.ident;
            return constants.Multiname(constants.namespaceset(flattenNamespaceSet(nss)), constants.stringUtf8(ident), is_attr);
        }
        public function qname(qn:Object, is_attr:Boolean ):int {
            //var {ns:ns, id:id} = qn;
            var ns:String = qn.ns, id:String = qn.id;
            return constants.QName(namespace(ns), constants.stringUtf8(id), is_attr);
        }
        public function nameFromIdent(id:String):int {
            return constants.QName(
				constants.namespace(AVM2Assembler.CONSTANT_PackageNamespace, constants.stringUtf8("")),
				constants.stringUtf8(id), false);
        }

        public function multinameL(tmp, is_attr) {
        	var nss=tmp.nss;
            return constants.MultinameL(constants.namespaceset(flattenNamespaceSet(nss)), is_attr);
        }

        public function rtqname(tmp, is_attr) {
        	var ident=tmp.ident;
            return constants.RTQName(constants.stringUtf8(ident), is_attr);
        }

        public function rtqnamel(is_attr) {
            return constants.RTQNameL(is_attr);
        }


    }
}