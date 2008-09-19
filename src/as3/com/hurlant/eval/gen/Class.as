package com.hurlant.eval.gen
{
	import com.hurlant.eval.Util;
	import com.hurlant.eval.abc.ABCClassInfo;
	
	public class Class
	{
        public var s, name, basename, traits=[], instance=null, cinit;

        function Class(script, name, basename) {
            this.s = script;
            this.name = name;
            this.basename = basename;

            var asm = script.init;
            // Create the class
 /*           asm.I_findpropstrict(Object_name);
            asm.I_getproperty(Object_name);
            asm.I_dup();
            asm.I_pushscope();
            asm.I_newclass(clsidx);
            asm.I_popscope();
            asm.I_getglobalscope();
            asm.I_swap();
            asm.I_initproperty(Fib_name);
*/
        }

        public function getCInit() {
            if(cinit == null )
                cinit = new Method(s.e, [], false, false, 0, "$cinit", true);
            return cinit;
        }

/*
        public function newIInit(formals, name) {
            var iinit = new Method(s.e, formals, false, false, 2, name, true);
            iinit.I_getlocal(0);
            iinit.I_constructsuper(0);
            return iinit;
        }
*/
        public function getInstance() {
            if( this.instance == null )
                this.instance = new Instance(s, name, basename);
            
            return this.instance;
        }
        
        public function addTrait(t) {
            traits.push(t);
        }

        public function finalize() {
            var instidx = instance.finalize();
            
            var clsinfo = new ABCClassInfo();
            clsinfo.setCInit(getCInit().finalize());
            for(var i = 0; i < traits.length; ++i)
                clsinfo.addTrait(traits[i]);
            
            var clsidx = s.e.file.addClass(clsinfo);
            
            Util.assert(clsidx == instidx);

            //s.addTrait(new ABCOtherTrait(name, 0, TRAIT_Class, 0, clsidx));
            return clsidx;
        }

	}
}