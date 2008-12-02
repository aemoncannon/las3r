package com.hurlant.eval.gen
{
	import com.hurlant.eval.abc.ABCScriptInfo;
	
	public class Script
	{
        public var e, init, traits=[];

        function Script(e:ABCEmitter) {
            this.e = e;
            this.init = new Method(e,[], false, false, 0, "", false);
        }

        public function newClass(name, basename) {
            return new com.hurlant.eval.gen.Class(this, name, basename);
        }

        /* All functions are in some sense global because the
           methodinfo and methodbody are both global. */
        public function newFunction(formals:Array, needRest:Boolean, needArguments:Boolean, initScopeDepth:int, name:String) {
            return new Method(e, formals, needRest, needArguments, initScopeDepth, name, false);
        }

        public function addException(e) {
            return init.addException(e);
        }
        // Here we probably want: newVar, newConst, ... instead?
        public function addTrait(t) {
            return traits.push(t);
        }

        public function finalize() {

            // Standard epilogue for lazy clients.
            this.init.asm.I_returnvoid();

            var id = init.finalize();
            var si = new ABCScriptInfo(id);
            for ( var i=0 ; i < traits.length ; i++ )
                si.addTrait(traits[i]);
            e.file.addScript(si);
        }
	}
}