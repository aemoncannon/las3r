package com.hurlant.eval.abc
{
	import com.hurlant.eval.Util;
	
    public class ABCClassInfo
    {
        public function setCInit(cinit) {
            this.cinit = cinit;
        }

        public function addTrait(t) {
            return traits.push(t)-1;
        }

        public function serialize(bs) {
            Util.assert( cinit != undefined );
            bs.uint30(cinit);
            bs.uint30(traits.length);
            for ( var i=0 ; i < traits.length ; i++ )
                traits[i].serialize(bs);
        }

        /*private*/ var cinit, traits = [];
    }
}