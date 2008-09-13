package com.hurlant.eval.ast
{
    public class ForInStmt implements IAstStmt {
    	public var vars: Head;
    	public var init: IAstExpr;
    	public var expr: IAstExpr;
    	public var stmt: IAstStmt;
    	public var labels:Array;
    	function ForInStmt (vars:Head, init:IAstExpr, expr:IAstExpr, stmt:IAstStmt, labels:Array) {
    		this.vars = vars;
    		this.init = init;
    		this.expr = expr;
    		this.stmt = stmt;
    		this.labels = labels;
    	}
    }
}