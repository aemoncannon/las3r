package com.hurlant.eval.abc
{
	import com.hurlant.eval.gen.AVM2Assembler;
	
    public class ABCOtherTrait /// extends ABCTrait  // removed for esc
    {
        /* TAG is one of the TRAIT_* values, except TRAIT_Slot */
        function ABCOtherTrait(name, attrs, tag, id, val) {
            /*FIXME #101: super not implemented*/
            //super(name, (attrs << 4) | tag);
            this.name = name;
            this.kind = (attrs << 4) | tag;
            this.metadata = [];
            //End of fixme
            this.id = id;
            this.val = val;
        }

        // esc doesn't support override yet
        public function inner_serialize(bs) {
            bs.uint30(id);
            bs.uint30(val);
        }

        /*private*/ var id, val;

        // from ABCTrait

        public function addMetadata(n) {
            return metadata.push(n)-1;
        }

        public function serialize(bs) {
            if (metadata.length > 0)
                kind = kind | AVM2Assembler.ATTR_Metadata;
            bs.uint30(name);
            bs.uint30(kind);
            inner_serialize(bs);
            if (metadata.length > 0) {
                bs.uint30(metadata.length);
                for ( var i=0 ; i < metadata.length ; i++ )
                    bs.uint30(metadata[i]);
            }
        }

        public var name, kind, metadata;


    }
}