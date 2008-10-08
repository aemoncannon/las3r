package com.hurlant.eval.abc
{
	import com.hurlant.eval.Util;
	
    public class ABCScriptInfo
    {
        function ABCScriptInfo(init) {
            this.init = init;
        }

        public function setInit(init) {
            this.init = init;
        }

        public function addTrait(t) {
            return traits.push(t)-1;
        }

        public function serialize(bs) {
            Util.assert( init != undefined );
            bs.uint30(init);
            bs.uint30(traits.length);
            for ( var i=0 ; i < traits.length ; i++ )
                traits[i].serialize(bs);
        }

        private var init, traits = [];
    }
}