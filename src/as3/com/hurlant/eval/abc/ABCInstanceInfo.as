package com.hurlant.eval.abc
{
	import com.hurlant.eval.Util;
	import com.hurlant.eval.gen.AVM2Assembler;
	
    public class ABCInstanceInfo
    {
        function ABCInstanceInfo(name, super_name, flags, protectedNS, interfaces) {
            this.name = name;
            this.super_name = super_name;
            this.flags = flags;
            this.protectedNS = protectedNS;
            this.interfaces = interfaces;
            this.traits = [];
        }

        public function setIInit(x) {
            iinit = x;
        }

        public function addTrait(t) {
            return traits.push(t)-1;
        }

        public function serialize(bs) {
            var i;

            Util.assert( iinit != undefined );

            bs.uint30(name);
            bs.uint30(super_name);
            bs.uint8(flags);
            if (flags & AVM2Assembler.CONSTANT_ClassProtectedNs)
                bs.uint30(protectedNS);
            bs.uint30(interfaces.length);
            for ( i=0 ; i < interfaces.length ; i++ ) {
                Util.assert( interfaces[i] != 0 );
                bs.uint30(interfaces[i]);
            }
            bs.uint30(iinit);
            bs.uint30(traits.length);
            for ( i=0 ; i < traits.length ; i++ )
                traits[i].serialize(bs);
        }

        private var name, super_name, flags, protectedNS, interfaces, iinit, traits;
    }
}