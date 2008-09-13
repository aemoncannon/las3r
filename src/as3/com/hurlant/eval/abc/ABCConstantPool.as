package com.hurlant.eval.abc
{
	import com.hurlant.eval.Util;
	import com.hurlant.eval.gen.AVM2Assembler;
	import com.hurlant.eval.gen.ABCByteStream;
	
    /* FIXME: we should be using hash tables here, not linear searching. */
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
        }

        /**/ function findOrAdd(x, pool, cmp, emit) {
            var i;
            for ( i=1 ; i < pool.length ; i++ )
                if (cmp(pool[i], x))
                    return i;

            emit(x);
            pool.push(x);
            return i;
        }

        /*private*/ function cmp(a, b) { return a === b }

        public function int32(n:int):uint {
            function temp_func (x) { int_bytes.int32(x) };
            return findOrAdd( n, int_pool, cmp, temp_func );
        }

        public function uint32(n:uint):uint {
            function temp_func(x) { uint_bytes.uint32(x) }
            return findOrAdd( n, uint_pool, cmp, temp_func );
        }

        public function float64(n: Number):uint {
            function temp_func(x) { double_bytes.float64(x) } 
            return findOrAdd( n, double_pool, cmp, temp_func);
        }

        public function stringUtf8(s/*FIXME ES4: string*/)/*:uint*/ {
            function temp_func(x) { utf8_bytes.uint30(x.length); utf8_bytes.utf8(x) }
            return findOrAdd( ""+s,  // FIXME need to make sure its a string
                              utf8_pool,
                              cmp,
                              temp_func )
        }

        /*private*/ function cmpname(a, b) {
            return a.kind == b.kind && a.ns == b.ns && a.name == b.name;
        }

        public function namespace(kind/*:uint*/, name/*:uint*/) {
            function temp_func(x) {
              namespace_bytes.uint8(x.kind);
              namespace_bytes.uint30(x.name); }
            return findOrAdd( { "kind": kind, "name": name },
                              namespace_pool,
                              cmpname,
                              temp_func );
        }

        /*private*/ function cmparray(a, b) {
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
                              namespaceset_pool,
                              cmparray,
                              temp_func );
        }

        public function QName(ns/*: uint*/, name/*: uint*/, is_attr: Boolean /*FIXME ES4: boolean*/) {
            function temp_func(x) {
              multiname_bytes.uint8(x.kind);
              multiname_bytes.uint30(x.ns);
              multiname_bytes.uint30(x.name); 
            }
            return findOrAdd( { "kind": is_attr ? AVM2Assembler.CONSTANT_QNameA : AVM2Assembler.CONSTANT_QName, "ns": ns, "name": name },
                              multiname_pool,
                              cmpname,
                              temp_func );
        }

        public function RTQName(name/*: uint*/, is_attr: Boolean /*FIXME ES4: boolean*/) {
            function temp_func(x) {
              multiname_bytes.uint8(x.kind);
              multiname_bytes.uint30(x.name); 
            }
            return findOrAdd( { "kind": is_attr ? AVM2Assembler.CONSTANT_RTQNameA : AVM2Assembler.CONSTANT_RTQName, "name": name },
                              multiname_pool,
                              cmpname,
                              temp_func );
        }

        public function RTQNameL(is_attr: Boolean /*FIXME ES4: boolean*/) {
            function temp_func (x) { multiname_bytes.uint8(x.kind) } 
            return findOrAdd( { "kind": is_attr ? AVM2Assembler.CONSTANT_RTQNameLA : AVM2Assembler.CONSTANT_RTQNameL },
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
            return findOrAdd( { "kind": is_attr ? AVM2Assembler.CONSTANT_MultinameA : AVM2Assembler.CONSTANT_Multiname, "name": name, "ns":nsset },
                              multiname_pool,
                              cmpname,
                              temp_func);
        }

        public function MultinameL(nsset/*: uint*/, is_attr: Boolean /*FIXME ES4: boolean*/) {
            function temp_func (x) {
              multiname_bytes.uint8(x.kind);
              multiname_bytes.uint30(x.ns); 
            }
            return findOrAdd( { "kind": is_attr ? AVM2Assembler.CONSTANT_MultinameLA : AVM2Assembler.CONSTANT_MultinameL, "ns":nsset },
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
        /*private*/ const int_pool = new Array;
        /*private*/ const uint_pool = new Array;
        /*private*/ const double_pool = new Array;
        /*private*/ const utf8_pool = new Array;
        /*private*/ const namespace_pool = new Array;
        /*private*/ const namespaceset_pool = new Array;
        /*private*/ const multiname_pool = new Array;

        /*private*/ const int_bytes = new ABCByteStream;
        /*private*/ const uint_bytes = new ABCByteStream;
        /*private*/ const double_bytes = new ABCByteStream;
        /*private*/ const utf8_bytes = new ABCByteStream;
        /*private*/ const namespace_bytes = new ABCByteStream;
        /*private*/ const namespaceset_bytes = new ABCByteStream;
        /*private*/ const multiname_bytes = new ABCByteStream;
    }
}