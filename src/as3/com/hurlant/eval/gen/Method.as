package com.hurlant.eval.gen
{
	import com.hurlant.eval.abc.ABCMethodBodyInfo;
	import com.hurlant.eval.abc.ABCMethodInfo;
	
    public class Method // extends AVM2Assembler
    {
        public var e, formals, name, asm, traits = [], finalized=false, defaults = null, exceptions=[];
		public var initScopeDepth;
        function Method(e:ABCEmitter, formals:Array, needRest:Boolean, needArguments:Boolean, initScopeDepth:int, name:String, standardPrologue:Boolean) {
            asm = new AVM2Assembler(e.constants, formals.length, needRest, needArguments, initScopeDepth);
            //super(e.constants, formals.length);
            this.formals = formals;
            this.initScopeDepth = initScopeDepth
            this.e = e;
            this.name = name;

            // Standard prologue -- but is this always right?
            // ctors don't need this - have a more complicated prologue
            if(standardPrologue)
            {
                asm.I_getlocal_0();
                asm.I_pushscope();
            }
        }

        public function addTrait(t) {
            return traits.push(t);
        }

        public function setDefaults(d) {
            defaults = d;
        }

        public function addException(e) {
            return exceptions.push(e)-1;
        }
        
        public function finalize() {
            if (finalized)
                return;
            finalized = true;

            var meth = e.file.addMethod(new ABCMethodInfo(0, formals, 0, asm.flags, defaults, null));
            var body = new ABCMethodBodyInfo(meth);
            body.setMaxStack(asm.maxStack);
            body.setLocalCount(asm.maxLocal);
            body.setInitScopeDepth(this.initScopeDepth);
            body.setMaxScopeDepth(asm.maxScope);
            body.setCode(asm.finalize());
            for ( var i=0 ; i < traits.length ; i++ )
                body.addTrait(traits[i]);
            
            for ( i=0 ; i < exceptions.length; i++ )
                body.addException(exceptions[i]);
            
            e.file.addMethodBody(body);

            return meth;
        }
    }
}