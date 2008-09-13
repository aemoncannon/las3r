package com.hurlant.eval.abc
{
	import com.hurlant.eval.Util;
	import com.hurlant.eval.gen.AVM2Assembler;
	
    public class ABCMethodInfo
    {
        /* \param name         string index
         * \param param_types  array of multiname indices.  May not be null.
         * \param return_type  multiname index.
         * \param flags        bitwise or of NEED_ARGUMENTS, NEED_ACTIVATION, HAS_REST, SET_DXNS
         * \param options      [{val:uint, kind:uint}], if present.
         * \param param_names  array of param_info structures, if present.
         */
        function ABCMethodInfo(name/*:uint*/, param_types:Array, return_type/*:uint*/, flags/*:uint*/,
                               options:Array, param_names:Array) {
            this.name = name;
            this.param_types = param_types;
            this.return_type = return_type;
            this.flags = flags;
            this.options = options;
            this.param_names = param_names;
        }

        public function setFlags(flags) {
            this.flags = flags;
        }

        public function serialize(bs) {
            var i;
            bs.uint30(param_types.length);
            bs.uint30(return_type);
            for ( i=0 ; i < param_types.length ; i++ ) {
                bs.uint30(param_types[i]);
            }
            bs.uint30(name);
            if (options != null) {
                flags = flags | AVM2Assembler.METHOD_HasOptional;
            }
            if (param_names != null) {
                flags = flags | AVM2Assembler.METHOD_HasParamNames;
            }
            bs.uint8(flags);
            if (options != null) {
                bs.uint30(options.length);
                for ( i=0 ; i < options.length ; i++ ) {
                    bs.uint30(options[i].val);
                    bs.uint8(options[i].kind);
                }
            }
            if (param_names != null) {
                Util.assert( param_names.length == param_types.length );
                for ( i=0 ; i < param_names.length ; i++ )
                    bs.uint30(param_names[i]);
            }
        }

        /*private*/ var name, param_types, return_type, flags, options, param_names;
    }
}