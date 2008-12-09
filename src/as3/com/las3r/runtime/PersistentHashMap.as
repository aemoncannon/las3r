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

		private var _count:int;
		private var root:INode;

		private static var _empty:PersistentHashMap;
		public static function empty():PersistentHashMap {
			_empty = _empty || new PersistentHashMap(0, new EmptyNode());
			return _empty;
		}


		public static function createFromMany(...init:Array):PersistentHashMap {
			return createFromArray(init);
		}

		public static function createFromArray(init:Array):PersistentHashMap {
			var ret:IMap = empty();
			for(var i:int = 0; i < init.length; i += 2)
			{
				ret = ret.assoc(init[i], init[i + 1]);
			}
			return PersistentHashMap(ret);
		}

		public static function createFromSeq(items:ISeq):PersistentHashMap{
			var ret:IMap = empty();
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
			_count = count;
			this.root = root;
		}


		override public function containsKey(key:Object):Boolean{
			return entryAt(key) != null;
		}

		override public function entryAt(key:Object):MapEntry {
			return root.find(Util.hash(key), key);
		}


		override public function assoc(key:Object, val:Object):IMap{
			var addedLeaf:Box = new Box(null);
			var newroot:INode = root.assoc(0, Util.hash(key), key, val, addedLeaf);
			if(newroot == root)
			return this;
			return new PersistentHashMap(addedLeaf.val == null ? _count : _count + 1, newroot, meta);
		}

		override public function valAt(key:Object, notFound:Object = null):Object{
			var e:MapEntry = entryAt(key);
			if(e != null)
			return e.value;
			return notFound;
		}

		public function assocEx(key:Object, val:Object):IMap{
			if(containsKey(key))
			throw new Error("Key already present");
			return assoc(key, val);
		}

		override public function without(key:Object):IMap{
			var newroot:INode = root.without(Util.hash(key), key);
			if(newroot == root)
			return this;
			if(newroot == null)
			return IMap(empty().withMeta(meta));
			return new PersistentHashMap(_count - 1, newroot, meta);
		}

		override public function count():int{
			return _count;
		}

		override public function seq():ISeq{
			return root.nodeSeq();
		}

		public static function mask(hash:int, shift:int):int{
			//return ((hash << shift) >>> 27);// & 0x01f;
			return (hash >>> shift) & 0x01f;
		}

		override public function withMeta(meta:IMap):IObj{
			return new PersistentHashMap(_count, root, meta);
		}
	}
}


import com.las3r.runtime.*;
import com.las3r.util.*;
import com.las3r.jdk.util.*;

interface INode{
	function assoc(shift:int, hash:int, key:Object, val:Object, addedLeaf:Box):INode;

	function without(hash:int, key:Object):INode;

	function find(hash:int, key:Object):LeafNode;

	function nodeSeq():ISeq;

	function getHash():int;
}

class EmptyNode implements INode{

	public function EmptyNode(){}

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
	public var nodes:Array;
	public var shift:int;
	private var _hash:int;


	private static function bitpos(hash:int, shift:int):int{
		return 1 << PersistentHashMap.mask(hash, shift);
	}

	public function FullNode(nodes:Array, shift:int){
		this.nodes = nodes;
		this.shift = shift;
		this._hash = nodes[0].getHash();
	}

	public function assoc(levelShift:int, hash:int, key:Object, val:Object, addedLeaf:Box):INode{
		//		if(levelShift < shift && diffPath(shift,hash,_hash))
		//			return BitmapIndexedNode.create(levelShift, this, hash, key, val, addedLeaf);
		var idx:int = PersistentHashMap.mask(hash, shift);

		var n:INode = nodes[idx].assoc(shift + 5, hash, key, val, addedLeaf);
		if(n == nodes[idx])
		return this;
		else
		{
			var newnodes:Array = ArrayUtil.clone(nodes);
			newnodes[idx] = n;
			return new FullNode(newnodes, shift);
		}
	}

	public function without(hash:int, key:Object):INode{
		//		if(diffPath(shift,hash,_hash))
		//			return this;
		var idx:int = PersistentHashMap.mask(hash, shift);
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
			newnodes = ArrayUtil.clone(nodes);
			newnodes[idx] = n;
			return new FullNode(newnodes, shift);
		}
		return this;
	}

	public function find(hash:int, key:Object):LeafNode{
		//		if(diffPath(shift,hash,_hash))
		//			return null;
		return nodes[PersistentHashMap.mask(hash, shift)].find(hash, key);
	}

	public function nodeSeq():ISeq{
		return FullNodeSeq.create(this, 0);
	}

	public function getHash():int{
		return _hash;
	}

}
class FullNodeSeq extends ASeq{
	private var s:ISeq;
	private var i:int;
	private var node:FullNode;

	public function FullNodeSeq(s:ISeq, i:int, node:FullNode, meta:IMap = null){
		super(meta);
		this.s = s;
		this.i = i;
		this.node = node;
	}

	public static function create(node:FullNode, i:int):ISeq{
		if(i >= node.nodes.length)
		return null;
		return new FullNodeSeq(node.nodes[i].nodeSeq(), i, node);
	}

	override public function first():Object{
		return s.first();
	}

	override public function rest():ISeq{
		var nexts:ISeq = s.rest();
		if(nexts != null)
		return new FullNodeSeq(nexts, i, node);
		return create(node, i + 1);
	}

	override public function withMeta(meta:IMap):IObj{
		return new FullNodeSeq(s, i, node, meta);
	}
}



class BitmapIndexedNode implements INode{
	public var bitmap:int;
	public var nodes:Array;
	public var shift:int;
	private var _hash:int;

	public static function bitpos(hash:int, shift:int):int{
		return 1 << PersistentHashMap.mask(hash, shift);
	}

	public function index(bit:int):int{
		return Numbers.bitCount(bitmap & (bit - 1));
	}

	public function BitmapIndexedNode(bitmap:int, nodes:Array, shift:int){
		this.bitmap = bitmap;
		this.nodes = nodes;
		this.shift = shift;
		this._hash = nodes[0].getHash();
	}

	public static function createFromBitmap(bitmap:int, nodes:Array, shift:int):INode{
		if(bitmap == -1)
		return new FullNode(nodes, shift);
		return new BitmapIndexedNode(bitmap, nodes, shift);
	}

	public static function create(shift:int, branch:INode, hash:int, key:Object, val:Object, addedLeaf:Box):INode{
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
				var newnodes:Array = ArrayUtil.clone(nodes);
				newnodes[idx] = n;
				return new BitmapIndexedNode(bitmap, newnodes, shift);
			}
		}
		else
		{
			newnodes = new Array(nodes.length + 1);
			ArrayUtil.arraycopy(nodes, 0, newnodes, 0, idx);
			addedLeaf.val = newnodes[idx] = new LeafNode(hash, key, val);
			ArrayUtil.arraycopy(nodes, idx, newnodes, idx + 1, nodes.length - idx);
			return createFromBitmap(bitmap | bit, newnodes, shift);
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
					var newnodes:Array = new Array(nodes.length - 1);
					ArrayUtil.arraycopy(nodes, 0, newnodes, 0, idx);
					ArrayUtil.arraycopy(nodes, idx + 1, newnodes, idx, nodes.length - (idx + 1));
					return new BitmapIndexedNode(bitmap & ~bit, newnodes, shift);
				}
				newnodes = ArrayUtil.clone(nodes);
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
		return BitmapIndexedNodeSeq.create(this, 0);
	}
}

class BitmapIndexedNodeSeq extends ASeq{
	private var s:ISeq;
	private var i:int;
	private var node:BitmapIndexedNode;


	public function BitmapIndexedNodeSeq(s:ISeq, i:int, node:BitmapIndexedNode, meta:IMap = null){
		super(meta);
		this.s = s;
		this.i = i;
		this.node = node;
	}

	public static function create(node:BitmapIndexedNode, i:int):ISeq{
		if(i >= node.nodes.length)
		return null;
		return new BitmapIndexedNodeSeq(node.nodes[i].nodeSeq(), i, node);
	}

	override public function first():Object{
		return s.first();
	}

	override public function rest():ISeq{
		var nexts:ISeq = s.rest();
		if(nexts != null)
		return new BitmapIndexedNodeSeq(nexts, i, node);
		return create(node, i + 1);
	}

	override public function withMeta(meta:IMap):IObj{
		return new BitmapIndexedNodeSeq(s, i, node, meta);
	}
}


class LeafNode extends MapEntry implements INode{
	private var hash:int;

	public function LeafNode(hash:int, key:Object, val:Object){
		super(key, val);
		this.hash = hash;
	}

	public function assoc(shift:int, hash:int, key:Object, val:Object, addedLeaf:Box):INode{
		if(hash == this.hash)
		{
			if(Util.equal(key, this.key))
			{
				if(val == this.value)
				return this;
				//note  - do not set addedLeaf, since we are replacing
				return new LeafNode(hash, key, val);
			}
			//hash collision - same hash, different keys
			var newLeaf:LeafNode = new LeafNode(hash, key, val);
			addedLeaf.val = newLeaf;
			return new HashCollisionNode(hash, this, newLeaf);
		}
		return BitmapIndexedNode.create(shift, this, hash, key, val, addedLeaf);
	}

	public function without(hash:int, key:Object):INode{
		if(hash == this.hash && Util.equal(key, this.key))
		return null;
		return this;
	}

	public function find(hash:int, key:Object):LeafNode{
		if(hash == this.hash && Util.equal(key, this.key))
		return this;
		return null;
	}

	public function nodeSeq():ISeq{
		return RT.cons(this, null);
	}

	public function getHash():int{
		return hash;
	}

	public function getKey():Object{
		return this.key;
	}

	public function getValue():Object{
		return this.value;
	}
}


class HashCollisionNode implements INode{
	private var hash:int;
	private var leaves:Array;

	public function HashCollisionNode(hash:int, ...leaves:Array){
		this.hash = hash;
		this.leaves = leaves;
	}

	public function assoc(shift:int, hash:int, key:Object, val:Object, addedLeaf:Box):INode {
		if(hash == this.hash)
		{
			var idx:int = findIndex(hash, key);
			if(idx != -1)
			{
				if(leaves[idx].val == val)
				return this;
				var newLeaves:Array = ArrayUtil.clone(leaves);
				//note  - do not set addedLeaf, since we are replacing
				newLeaves[idx] = new LeafNode(hash, key, val);
				return new HashCollisionNode(hash, newLeaves);
			}
			newLeaves = new Array(leaves.length + 1);
			ArrayUtil.arraycopy(leaves, 0, newLeaves, 0, leaves.length);
			addedLeaf.val = newLeaves[leaves.length] = new LeafNode(hash, key, val);
			return new HashCollisionNode(hash, newLeaves);
		}
		return BitmapIndexedNode.create(shift, this, hash, key, val, addedLeaf);
	}

	public function without(hash:int, key:Object):INode{
		var idx:int = findIndex(hash, key);
		if(idx == -1)
		return this;
		if(leaves.length == 2)
		return idx == 0 ? leaves[1] : leaves[0];
		var newLeaves:Array = new Array(leaves.length - 1);
		ArrayUtil.arraycopy(leaves, 0, newLeaves, 0, idx);
		ArrayUtil.arraycopy(leaves, idx + 1, newLeaves, idx, leaves.length - (idx + 1));
		return new HashCollisionNode(hash, newLeaves);
	}

	public function find(hash:int, key:Object):LeafNode{
		var idx:int = findIndex(hash, key);
		if(idx != -1)
		return leaves[idx];
		return null;
	}

	public function nodeSeq():ISeq{
		return ArraySeq.create(leaves);
	}

	private function findIndex(hash:int, key:Object):int{
		for(var i:int = 0; i < leaves.length; i++)
		{
			if(INode(leaves[i]).find(hash, key) != null)
			return i;
		}
		return -1;
	}

	public function getHash():int{
		return hash;
	}
}

