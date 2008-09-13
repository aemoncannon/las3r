package com.hurlant.eval.abc
{
	import com.hurlant.eval.Util;
	
    public class ABCMetadataInfo
    {
        function ABCMetadataInfo( name/*: uint*/, items: Array ) {
            Util.assert( name != 0 );
            this.name = name;
            this.items = items;
        }

        public function serialize(bs) {
            bs.uint30(name);
            bs.uint30(items.length);
            for ( var i=0 ; i < items.length ; i++ ) {
                bs.uint30(items[i].key);
                bs.uint30(items[i].value);
            }
        }

        /*private*/ var name, items;
    }
}