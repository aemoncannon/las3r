package com.hurlant.eval.abc
{
	import com.hurlant.eval.Util;
	import com.hurlant.eval.gen.AVM2Assembler;
	import com.hurlant.eval.gen.ABCByteStream;
	import flash.utils.Dictionary;
	
    public class ABCConstantPool
    {
        function ABCConstantPool() {
            // All pools start at 1.
            int_pool.length = 1;
            uint_pool.length = 1;
            double_pool.length = 1;
            utf8_pool.length = 1;
            namespace_pool.length = 1;
            namespaceset_pool.length = 1;
            multiname_pool.length = 1;

			poolDict[int_pool] = new Dictionary();
			poolDict[uint_pool] = new Dictionary();
			poolDict[double_pool] = new Dictionary();
			poolDict[utf8_pool] = new Dictionary();
			poolDict[namespace_pool] = new Dictionary();
			poolDict[namespaceset_pool] = new Dictionary();
			poolDict[multiname_pool] = new Dictionary();
        }

        private function findOrAdd(x:*, hashKey:*, pool:Array, cmp:Function, emit:Function):int {
			var dict:Dictionary = poolDict[pool];
			var existing:* = dict[hashKey];
			if(existing !== null && existing is int){
				return existing;
			}
			else{
				emit(x);
				pool.push(x);
				var id:int = (pool.length - 1);
				dict[hashKey] = id;
				return id;
			}
        }

        private function cmp(a, b) { return a === b }

        public function int32(n:int):uint {
            function temp_func (x) { int_bytes.int32(x) };
            return findOrAdd( n, n, int_pool, cmp, temp_func );
        }

        public function uint32(n:uint):uint {
            function temp_func(x) { uint_bytes.uint32(x) }
            return findOrAdd( n, n, uint_pool, cmp, temp_func );
        }

        public function float64(n: Number):uint {
            function temp_func(x) { double_bytes.float64(x) } 
            return findOrAdd( n, n, double_pool, cmp, temp_func);
        }

        public function stringUtf8(s/*FIXME ES4: string*/)/*:uint*/ {
            function temp_func(x) { utf8_bytes.uint30(x.length); utf8_bytes.utf8(x) }
            return findOrAdd( "" + s,  // FIXME need to make sure its a string
				s,
                utf8_pool,
                cmp,
                temp_func )
        }

        private function cmpname(a, b) {
            return a.kind == b.kind && a.ns == b.ns && a.name == b.name;
        }

        public function namespace(kind/*:uint*/, name/*:uint*/):int {
            function temp_func(x) {
				namespace_bytes.uint8(x.kind);
				namespace_bytes.uint30(x.name); }
            return findOrAdd( { "kind": kind, "name": name },
				kind + "_" + name,
                namespace_pool,
                cmpname,
                temp_func );
        }

        private function cmparray(a, b) {
            var i;
            if (a.length != b.length)
            return false;
            for ( i=0 ; i < a.length ; i++ )
            if (a[i] != b[i])
            return false;
            return true;
        }

        public function namespaceset(namespaces:Array) {
            function temp_func (x) {
				namespaceset_bytes.uint30(x.length);
				for ( var i=0 ; i < x.length ; i++ )
                namespaceset_bytes.uint30(x[i]);
            }
            return findOrAdd( Util.copyArray(namespaces),
				namespaces.join("_"),
                namespaceset_pool,
                cmparray,
                temp_func );
        }

        public function QName(ns/*: uint*/, name/*: uint*/, is_attr: Boolean) {
            function temp_func(x) {
				multiname_bytes.uint8(x.kind);
				multiname_bytes.uint30(x.ns);
				multiname_bytes.uint30(x.name); 
            }
			var kind = is_attr ? AVM2Assembler.CONSTANT_QNameA : AVM2Assembler.CONSTANT_QName;
            return findOrAdd( { "kind": kind, "ns": ns, "name": name },
				kind + "_" + ns + "_" + name,
                multiname_pool,
                cmpname,
                temp_func );
        }

        public function RTQName(name/*: uint*/, is_attr: Boolean) {
            function temp_func(x) {
				multiname_bytes.uint8(x.kind);
				multiname_bytes.uint30(x.name); 
            }
			var kind = is_attr ? AVM2Assembler.CONSTANT_RTQNameA : AVM2Assembler.CONSTANT_RTQName;
            return findOrAdd( { "kind": kind, "name": name },
				kind + "_" + name,
                multiname_pool,
                cmpname,
                temp_func );
        }

        public function RTQNameL(is_attr: Boolean /*FIXME ES4: boolean*/) {
            function temp_func (x) { multiname_bytes.uint8(x.kind) } 
			var kind = is_attr ? AVM2Assembler.CONSTANT_RTQNameLA : AVM2Assembler.CONSTANT_RTQNameL;
            return findOrAdd( { "kind": kind },
				kind + "",
                multiname_pool,
                cmpname,
                temp_func);
        }

        public function Multiname(nsset/*: uint*/, name/*: uint*/, is_attr: Boolean /*FIXME ES4: boolean*/ ) {
            function temp_func(x) {
                multiname_bytes.uint8(x.kind);
                multiname_bytes.uint30(x.name);
                multiname_bytes.uint30(x.ns); 
            } 
			var kind = is_attr ? AVM2Assembler.CONSTANT_MultinameA : AVM2Assembler.CONSTANT_Multiname;
            return findOrAdd( { "kind": kind, "name": name, "ns":nsset },
				kind + "_" + name + "_" + nsset,
                multiname_pool,
                cmpname,
                temp_func);
        }

        public function MultinameL(nsset/*: uint*/, is_attr: Boolean /*FIXME ES4: boolean*/) {
            function temp_func (x) {
				multiname_bytes.uint8(x.kind);
				multiname_bytes.uint30(x.ns); 
            }
			var kind = is_attr ? AVM2Assembler.CONSTANT_MultinameLA : AVM2Assembler.CONSTANT_MultinameL;
            return findOrAdd( { "kind": kind, "ns":nsset },
				kind + "_" + nsset,
                multiname_pool,
                cmpname,
                temp_func );
        }

        public function hasRTNS(index) {
            var kind = multiname_pool[index].kind;
            var result;
            switch (kind) {
				case AVM2Assembler.CONSTANT_RTQName:
				case AVM2Assembler.CONSTANT_RTQNameA:
				case AVM2Assembler.CONSTANT_RTQNameL:
				case AVM2Assembler.CONSTANT_RTQNameLA:
                result = true;
				default:
                result = false;
            }
            return result;
        }

        public function hasRTName(index) {
            var kind = multiname_pool[index].kind;
            var result;
            switch (multiname_pool[index].kind) {
				case AVM2Assembler.CONSTANT_RTQNameL:
				case AVM2Assembler.CONSTANT_RTQNameLA:
				case AVM2Assembler.CONSTANT_MultinameL:
				case AVM2Assembler.CONSTANT_MultinameLA:
                result = true;
				default:
                result = false;
            }
            return result;
        }

        public function serialize(bs) {
            bs.uint30(int_pool.length);
            bs.byteStream(int_bytes);

            bs.uint30(uint_pool.length);
            bs.byteStream(uint_bytes);

            bs.uint30(double_pool.length);
            bs.byteStream(double_bytes);

            bs.uint30(utf8_pool.length);
            bs.byteStream(utf8_bytes);

            bs.uint30(namespace_pool.length);
            bs.byteStream(namespace_bytes);

            bs.uint30(namespaceset_pool.length);
            bs.byteStream(namespaceset_bytes);

            bs.uint30(multiname_pool.length);
            bs.byteStream(multiname_bytes);

            return bs;
        }

        private const int_pool:Array = new Array();
        private const uint_pool:Array = new Array();
        private const double_pool:Array = new Array();
        private const utf8_pool:Array = new Array();
        private const namespace_pool:Array = new Array();
        private const namespaceset_pool:Array = new Array();
        private const multiname_pool:Array = new Array();

		private const poolDict:Dictionary = new Dictionary();

        private const int_bytes:ABCByteStream = new ABCByteStream();
        private const uint_bytes:ABCByteStream = new ABCByteStream();
        private const double_bytes:ABCByteStream = new ABCByteStream();
        private const utf8_bytes:ABCByteStream = new ABCByteStream();
        private const namespace_bytes:ABCByteStream = new ABCByteStream();
        private const namespaceset_bytes:ABCByteStream = new ABCByteStream();
        private const multiname_bytes:ABCByteStream = new ABCByteStream();
    }
}