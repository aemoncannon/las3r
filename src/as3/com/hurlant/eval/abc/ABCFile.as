package com.hurlant.eval.abc
{
	import com.hurlant.eval.Util;
	import com.hurlant.eval.gen.ABCByteStream;
	
    /* ABCFile container & helper class.
     *
     * Every argument to an addWhatever() method is retained by
     * reference.  When getBytes() is finally called, each object is
     * serialized.  The order of serialization is the order they will
     * have in the ABCFile, and the order among items of the same type
     * is the order in which they were added.
     *
     * Performance ought to be good; nothing is serialized more than
     * once and no data are copied except during serialization.
     */

    public class ABCFile
    {
        public const major_version = 46;
        public const minor_version = 16;

        private const methods = [];
        private const metadatas = [];
        private const instances = [];
        private const classes = [];
        private const scripts = [];
        private const bodies = [];
        public var constants : ABCConstantPool;

        public function getBytes(): * /* same type as ABCByteStream.getBytes() */ {
            function emitArray(a, len) {
                if (len)
                    bytes.uint30(a.length);
                for ( var i=0 ; i < a.length ; i++ )
                    a[i].serialize(bytes);
            }

            var bytes = new ABCByteStream;

            Util.assert(constants);
            Util.assert(scripts.length != 0);
            Util.assert(methods.length != 0);
            Util.assert(bodies.length != 0);
            Util.assert(classes.length == instances.length);

            // print ("emitting version");
            bytes.uint16(minor_version);
            bytes.uint16(major_version);
            // print ("emitting constants");
            constants.serialize(bytes);
            // print ("emitting methods");
            emitArray(methods,true);
            // print ("emitting metadatas");
            emitArray(metadatas,true);
            // print ("emitting instances");
            emitArray(instances,true);
            // print ("emitting classes");
            emitArray(classes, false);
            // print ("emitting scripts");
            emitArray(scripts,true);
            // print ("emitting bodies");
            emitArray(bodies,true);
            return bytes.getBytes();
        }

        public function addConstants(cpool: ABCConstantPool): void {
            constants = cpool;
        }

        public function addMethod(m: ABCMethodInfo)/*: uint*/ {
            return methods.push(m)-1;
        }

        public function addMetadata(m: ABCMetadataInfo)/*: uint*/ {
            return metadatas.push(m)-1;
        }

        public function addClassAndInstance(cls, inst)/*: uint*/ {
            var x = addClass(cls);
            var y = addInstance(inst);
            Util.assert( x == y );
            return x;
        }

        public function addInstance(i: ABCInstanceInfo)/*: uint*/ {
            return instances.push(i)-1;
        }

        public function addClass(c: ABCClassInfo)/*: uint*/ {
            return classes.push(c)-1;
        }

        public function addScript(s: ABCScriptInfo)/*: uint*/ {
            return scripts.push(s)-1;
        }

        public function addMethodBody(b: ABCMethodBodyInfo)/*: uint*/ {
            return bodies.push(b)-1;
        }
        
    }
}