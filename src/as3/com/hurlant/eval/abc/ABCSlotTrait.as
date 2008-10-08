package com.hurlant.eval.abc
{
	import com.hurlant.eval.gen.AVM2Assembler;
	
    public class ABCSlotTrait /// extends ABCTrait
    {
        function ABCSlotTrait(name, attrs, is_const, slot_id, type_name, vindex, vkind) {
            /*FIXME #101: super not implemented*/
            //super(name, (attrs << 4) | TRAIT_Slot);
            this.name = name;
            this.kind = (attrs << 4) | (is_const ? AVM2Assembler.TRAIT_Const : AVM2Assembler.TRAIT_Slot);
            this.metadata = [];
            //End of fixme
            this.slot_id = slot_id;
            this.type_name = type_name;
            this.vindex = vindex;
            this.vkind = vkind;
        }

        public function inner_serialize(bs) {
            bs.uint30(slot_id);
            bs.uint30(type_name);
            bs.uint30(vindex);
            if (vindex != 0)
                bs.uint8(vkind);
        }

        private var slot_id, type_name, vindex, vkind;

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