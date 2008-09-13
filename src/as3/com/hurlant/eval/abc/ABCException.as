package com.hurlant.eval.abc
{
    public class ABCException
    {
        function ABCException(first_pc, last_pc, target_pc, exc_type, var_name) {
            this.first_pc = first_pc;
            this.last_pc = last_pc;
            this.target_pc = target_pc;
            this.exc_type = exc_type;
            this.var_name = var_name;
        }

        public function serialize(bs) {
            bs.uint30(first_pc);
            bs.uint30(last_pc);
            bs.uint30(target_pc);
            bs.uint30(exc_type);
            bs.uint30(var_name);
        }

        /*private*/ var first_pc, last_pc, target_pc, exc_type, var_name;
    }
}