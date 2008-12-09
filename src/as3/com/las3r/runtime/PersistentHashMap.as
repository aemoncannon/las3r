/**
*   Copyright (c) Rich Hickey. All rights reserved.
*   Copyright (c) Aemon Cannon. All rights reserved.
*   The use and distribution terms for this software are covered by the
*   Common Public License 1.0 (http://opensource.org/licenses/cpl.php)
*   which can be found in the file CPL.TXT at the root of this distribution.
*   By using this software in any fashion, you are agreeing to be bound by
* 	 the terms of this license.
*   You must not remove this notice, or any other, from this software.
**/

package com.las3r.runtime{

	import flash.utils.Dictionary;
	import com.las3r.util.Util;
	import com.las3r.jdk.util.ArrayUtil;

	public class PersistentHashMap extends APersistentMap{

		private count:int;
		private root:INode;

		public static EMPTY:PersistentHashMap = new PersistentHashMap(0, new EmptyNode());


		public static function createFromMany(...init:Array):PersistentHashMap {
			return createFromArray(init);
		}

		public static function createFromArray(init:Array):PersistentHashMap {
			var ret:IMap = EMPTY;
			for(var i:int = 0; i < init.length; i += 2)
			{
				ret = ret.assoc(init[i], init[i + 1]);
			}
			return PersistentHashMap(ret);
		}

		public static function createFromSeq(items:ISeq):PersistentHashMap{
			var ret:IMap = EMPTY;
			for(; items != null; items = items.rest().rest())
			{
				if(items.rest() == null)
				throw new Error("IllegalArgumentException: No value supplied for key: " + items.first());
				ret = ret.assoc(items.first(), RT.second(items));
			}
			return PersistentHashMap(ret);
		}

		public function PersistentHashMap(count:int, root:INode, meta:IMap = null){
			super(meta);
			this.count = count;
			this.root = root;
		}


		public function containsKey(key:Object):Boolean{
			return entryAt(key) != null;
		}

		public function entryAt(key:Object):MapEntry {
			return root.find(Util.hash(key), key);
		}


		public function assoc(key:Object, val:Object):IMap{
			var addedLeaf:Box = new Box(null);
			var newroot:INode = root.assoc(0, Util.hash(key), key, val, addedLeaf);
			if(newroot == root)
			return this;
			return new PersistentHashMap(addedLeaf.val == null ? count : count + 1, newroot, meta);
		}

		public function valAt(key:Object, notFound:Object = null):Object{
			var e:MapEntry = entryAt(key);
			if(e != null)
			return e.val();
			return notFound;
		}

		public function valAt(key:Object):Object{
			return valAt(key, null);
		}

		public function assocEx(key:Object, val:Object):IMap{
			if(containsKey(key))
			throw new Error("Key already present");
			return assoc(key, val);
		}

		public function without(key:Object):IMap{
			var newroot:INode = root.without(Util.hash(key), key);
			if(newroot == root)
			return this;
			if(newroot == null)
			return EMPTY.withMeta(meta());
			return new PersistentHashMap(count - 1, newroot, meta);
		}

		public function count():int{
			return count;
		}

		public function seq():ISeq{
			return root.nodeSeq();
		}

		private static function mask(hash:int, shift:int):int{
			//return ((hash << shift) >>> 27);// & 0x01f;
			return (hash >>> shift) & 0x01f;
		}

		public function withMeta(meta:IMap):IObj{
			return new PersistentHashMap(count, root, meta);
		}
	}
}

interface INode{
	function assoc(shift:int, hash:int, key:Object, val:Object, addedLeaf:Box):INode;

	function without(hash:int, key:Object):INode;

	function find(hash:int, key:Object):LeafNode;

	function nodeSeq():ISeq;

	function getHash():int;
}

class EmptyNode implements INode{

	public function assoc(shift:int, hash:int, key:Object, val:Object, addedLeaf:Box):INode{
		var ret:INode = new LeafNode(hash, key, val);
		addedLeaf.val = ret;
		return ret;
	}

	public function without(hash:int, key:Object):INode{
		return this;
	}

	public function find(hash:int, key:Object):LeafNode{
		return null;
	}

	public function nodeSeq():ISeq {
		return null;
	}

	public function getHash():int{
		return 0;
	}
}

class FullNode implements INode{
	private var nodes:Array;
	private var shift:int;
	private var _hash:int;


	private static function bitpos(hash:int, shift:int):int{
		return 1 << mask(hash, shift);
	}

	public function FullNode(nodes:Array, shift:int){
		this.nodes = nodes;
		this.shift = shift;
		this._hash = nodes[0].getHash();
	}

	public function assoc(levelShift:int, hash:int, key:Object, val:Object, addedLeaf:Box):INode{
		//		if(levelShift < shift && diffPath(shift,hash,_hash))
		//			return BitmapIndexedNode.create(levelShift, this, hash, key, val, addedLeaf);
		var idx:int = mask(hash, shift);

		var n:INode = nodes[idx].assoc(shift + 5, hash, key, val, addedLeaf);
		if(n == nodes[idx])
		return this;
		else
		{
			var newnodes:Array = nodes.clone();
			newnodes[idx] = n;
			return new FullNode(newnodes, shift);
		}
	}

	public function without(hash:int, key:Object):INode{
		//		if(diffPath(shift,hash,_hash))
		//			return this;
		var idx:int = mask(hash, shift);
		var n:INode = nodes[idx].without(hash, key);
		if(n != nodes[idx])
		{
			if(n == null)
			{
				var newnodes:Array = new Array(nodes.length - 1);
				ArrayUtil.arraycopy(nodes, 0, newnodes, 0, idx);
				ArrayUtil.arraycopy(nodes, idx + 1, newnodes, idx, nodes.length - (idx + 1));
				return new BitmapIndexedNode(~bitpos(hash, shift), newnodes, shift);
			}
			var newnodes:Array = nodes.clone();
			newnodes[idx] = n;
			return new FullNode(newnodes, shift);
		}
		return this;
	}

	public function find(hash:int, key:Object):LeafNode{
		//		if(diffPath(shift,hash,_hash))
		//			return null;
		return nodes[mask(hash, shift)].find(hash, key);
	}

	public function nodeSeq():ISeq{
		return Seq.create(this, 0);
	}

	public function getHash():int{
		return _hash;
	}

}

class Seq extends ASeq{
	private var s:ISeq;
	private var i:int;
	private var node:FullNode;

	public function Seq(s:ISeq, i:int, node:FullNode, meta:IMap = null){
		super(meta);
		this.s = s;
		this.i = i;
		this.node = node;
	}

	public static create(node:FullNode, i:int):ISeq{
		if(i >= node.nodes.length)
		return null;
		return new Seq(node.nodes[i].nodeSeq(), i, node);
	}

	override public function first():Object{
		return s.first();
	}

	override public function rest():ISeq{
		ISeq nexts = s.rest();
		if(nexts != null)
		return new Seq(nexts, i, node);
		return create(node, i + 1);
	}

	override public function withMeta(meta:IMap):IObj{
		return new Seq(meta, s, i, node);
	}
}


class BitmapIndexedNode implements INode{
	private var bitmap:int;
	private var nodes:Array;
	private var shift:int;
	private var _hash:int;

	static function bitpos(hash:int, shift:int):int{
		return 1 << mask(hash, shift);
	}

	public function index(bit:int):int{
		return Integer.bitCount(bitmap & (bit - 1));
	}


	public function BitmapIndexedNode(bitmap:int, nodes:Array, shift:int){
		this.bitmap = bitmap;
		this.nodes = nodes;
		this.shift = shift;
		this._hash = nodes[0].getHash();
	}

	public static function create(bitmap:int, nodes:Array, shift:int):INode{
		if(bitmap == -1)
		return new FullNode(nodes, shift);
		return new BitmapIndexedNode(bitmap, nodes, shift);
	}

	public static create(shift:int, branch:INode, hash:int, key:Object, val:Object, addedLeaf:Box):INode{
		//		hx:int = branch.getHash()^hash;
		//		while(mask(hx,shift) == 0)
		//			shift += 5;
		//		if(mask(branch.getHash(),shift) == mask(hash,shift))
		//			return create(shift+5,branch,hash,key,val,addedLeaf);
		return (new BitmapIndexedNode(bitpos(branch.getHash(), shift), [ branch ], shift)).assoc(shift, hash, key, val, addedLeaf);
	}

	public function assoc(levelShift:int, hash:int, key:Object, val:Object, addedLeaf:Box):INode{
		//		if(levelShift < shift && diffPath(shift,hash,_hash))
		//			return create(levelShift, this, hash, key, val, addedLeaf);
		var bit:int = bitpos(hash, shift);
		var idx:int = index(bit);
		if((bitmap & bit) != 0)
		{
			var n:INode = nodes[idx].assoc(shift + 5, hash, key, val, addedLeaf);
			if(n == nodes[idx])
			return this;
			else
			{
				var newnodes:Array = nodes.clone();
				newnodes[idx] = n;
				return new BitmapIndexedNode(bitmap, newnodes, shift);
			}
		}
		else
		{
			var newnodes:Array = new Array(nodes.length + 1);
			ArrayUtil.arraycopy(nodes, 0, newnodes, 0, idx);
			addedLeaf.val = newnodes[idx] = new LeafNode(hash, key, val);
			ArrayUtil.arraycopy(nodes, idx, newnodes, idx + 1, nodes.length - idx);
			return create(bitmap | bit, newnodes, shift);
		}
	}

	public function without(hash:int, key:Object):INode{
		//		if(diffPath(shift,hash,_hash))
		//			return this;
		var bit:int = bitpos(hash, shift);
		if((bitmap & bit) != 0)
		{
			var idx:int = index(bit);
			var n:INode = nodes[idx].without(hash, key);
			if(n != nodes[idx])
			{
				if(n == null)
				{
					if(bitmap == bit)
					return null;
					//					if(nodes.length == 2)
					//						return nodes[idx == 0?1:0];
					var newnodes:Array = new INode[nodes.length - 1];
					ArrayUtil.arraycopy(nodes, 0, newnodes, 0, idx);
					ArrayUtil.arraycopy(nodes, idx + 1, newnodes, idx, nodes.length - (idx + 1));
					return new BitmapIndexedNode(bitmap & ~bit, newnodes, shift);
				}
				var newnodes:Array = nodes.clone();
				newnodes[idx] = n;
				return new BitmapIndexedNode(bitmap, newnodes, shift);
			}
		}
		return this;
	}

	public function find(hash:int, key:Object):LeafNode{
		//		if(diffPath(shift,hash,_hash))
		//			return null;
		var bit:int = bitpos(hash, shift);
		if((bitmap & bit) != 0)
		{
			return nodes[index(bit)].find(hash, key);
		}
		else
		return null;
	}

	public function getHash():int{
		return _hash;
	}

	public function nodeSeq():ISeq{
		return Seq.create(this, 0);
	}

	static class Seq extends ASeq{
		private var ISeq s;
		private var i:int;
		private var BitmapIndexedNode node;


		Seq(ISeq s, i:int, BitmapIndexedNode node){
			this.s = s;
			this.i = i;
			this.node = node;
		}

		Seq(meta:IMap, ISeq s, i:int, BitmapIndexedNode node){
			super(meta);
			this.s = s;
			this.i = i;
			this.node = node;
		}

		static ISeq create(BitmapIndexedNode node, i:int){
			if(i >= node.nodes.length)
			return null;
			return new Seq(node.nodes[i].nodeSeq(), i, node);
		}

		public Object first(){
			return s.first();
		}

		public ISeq rest(){
			ISeq nexts = s.rest();
			if(nexts != null)
			return new Seq(nexts, i, node);
			return create(node, i + 1);
		}

		public Seq withMeta(meta:IMap){
			return new Seq(meta, s, i, node);
		}
	}


}

class LeafNode extends AMapEntry implements INode{
	private var hash:int;
	private var key:Object;
	private var val:Object;

	public LeafNode(hash:int, key:Object, val:Object){
		this.hash = hash;
		this.key = key;
		this.val = val;
	}

	public INode assoc(shift:int, hash:int, key:Object, val:Object, Box addedLeaf){
		if(hash == this.hash)
		{
			if(Util.equal(key, this.key))
			{
				if(val == this.val)
				return this;
				//note  - do not set addedLeaf, since we are replacing
				return new LeafNode(hash, key, val);
			}
			//hash collision - same hash, different keys
			LeafNode newLeaf = new LeafNode(hash, key, val);
			addedLeaf.val = newLeaf;
			return new HashCollisionNode(hash, this, newLeaf);
		}
		return BitmapIndexedNode.create(shift, this, hash, key, val, addedLeaf);
	}

	public INode without(hash:int, key:Object){
		if(hash == this.hash && Util.equal(key, this.key))
		return null;
		return this;
	}

	public LeafNode find(hash:int, key:Object){
		if(hash == this.hash && Util.equal(key, this.key))
		return this;
		return null;
	}

	public ISeq nodeSeq(){
		return RT.cons(this, null);
	}

	public int getHash(){
		return hash;
	}

	public Object key(){
		return this.key;
	}

	public Object val(){
		return this.val;
	}

	public Object getKey(){
		return this.key;
	}

	public Object getValue(){
		return this.val;
	}
}

class HashCollisionNode implements INode{

	private var hash:int;
	private var leaves:Array;

	public HashCollisionNode(hash:int, LeafNode... leaves){
		this.hash = hash;
		this.leaves = leaves;
	}

	public INode assoc(shift:int, hash:int, key:Object, val:Object, Box addedLeaf){
		if(hash == this.hash)
		{
			idx:int = findIndex(hash, key);
			if(idx != -1)
			{
				if(leaves[idx].val == val)
				return this;
				LeafNode[] newLeaves = leaves.clone();
				//note  - do not set addedLeaf, since we are replacing
				newLeaves[idx] = new LeafNode(hash, key, val);
				return new HashCollisionNode(hash, newLeaves);
			}
			LeafNode[] newLeaves = new LeafNode[leaves.length + 1];
			ArrayUtil.arraycopy(leaves, 0, newLeaves, 0, leaves.length);
			addedLeaf.val = newLeaves[leaves.length] = new LeafNode(hash, key, val);
			return new HashCollisionNode(hash, newLeaves);
		}
		return BitmapIndexedNode.create(shift, this, hash, key, val, addedLeaf);
	}

	public INode without(hash:int, key:Object){
		idx:int = findIndex(hash, key);
		if(idx == -1)
		return this;
		if(leaves.length == 2)
		return idx == 0 ? leaves[1] : leaves[0];
		LeafNode[] newLeaves = new LeafNode[leaves.length - 1];
		ArrayUtil.arraycopy(leaves, 0, newLeaves, 0, idx);
		ArrayUtil.arraycopy(leaves, idx + 1, newLeaves, idx, leaves.length - (idx + 1));
		return new HashCollisionNode(hash, newLeaves);
	}

	public LeafNode find(hash:int, key:Object){
		idx:int = findIndex(hash, key);
		if(idx != -1)
		return leaves[idx];
		return null;
	}

	public ISeq nodeSeq(){
		return ArraySeq.create((Object[]) leaves);
	}

	int findIndex(hash:int, key:Object){
		for(i:int = 0; i < leaves.length; i++)
		{
			if(leaves[i].find(hash, key) != null)
			return i;
		}
		return -1;
	}

	public int getHash(){
		return hash;
	}
}

