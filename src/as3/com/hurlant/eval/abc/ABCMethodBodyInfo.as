package com.hurlant.eval.abc
{
	import com.hurlant.eval.Util;
	
    public class ABCMethodBodyInfo
    {
        function ABCMethodBodyInfo(method) {
            this.method = method;
        }
        public function setMaxStack(ms) { max_stack = ms }
        public function setLocalCount(lc) { local_count = lc }
        public function setInitScopeDepth(sd) { init_scope_depth = sd }
        public function setMaxScopeDepth(msd) { max_scope_depth = msd }
        public function setCode(insns) { code = insns }

        public function addException(exn) {
            return exceptions.push(exn)-1;
        }

        public function addTrait(t) {
            return traits.push(t)-1;
        }

        public function serialize(bs) {
            Util.assert( max_stack != undefined && local_count != undefined );
            Util.assert( init_scope_depth != undefined && max_scope_depth != undefined );
            Util.assert( code != undefined );

            bs.uint30(method);
            bs.uint30(max_stack);
            bs.uint30(local_count);
            bs.uint30(init_scope_depth);
            bs.uint30(max_scope_depth);
            bs.uint30(code.length);
            code.serialize(bs);
            bs.uint30(exceptions.length);
            for ( var i=0 ; i < exceptions.length ; i++ )
                exceptions[i].serialize(bs);
            bs.uint30(traits.length);
            for ( var i=0 ; i < traits.length ; i++ )
                traits[i].serialize(bs);
        }

        /*private*/ var init_scope_depth = 0, exceptions = [], traits = [];
        /*private*/ var method, max_stack, local_count, max_scope_depth, code;
    }
}