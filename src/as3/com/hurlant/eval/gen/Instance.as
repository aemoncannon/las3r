package com.hurlant.eval.gen
{
	import com.hurlant.eval.abc.ABCInstanceInfo;
	
    public class Instance {
        // FIXME: interfaces
        
        public var s, name, basename, traits = [], iinit;
        
        function Instance(s:Script, name, basename)  { 
            this.s=s; 
            this.name=name; 
            this.basename=basename;
            
        }
        
        public function setIInit(method) {
            iinit = method
        }
        public function addTrait(t) {
            traits.push(t);
        }
        
        public function finalize() {
            var instinfo = new ABCInstanceInfo(name, basename, 0, 0, []);
            
            instinfo.setIInit(iinit);
            
            for(var i = 0; i < traits.length; i++)
                instinfo.addTrait(traits[i]);
            
            return s.e.file.addInstance(instinfo);
        }
    }
}