module Resolve

import AST;

/*
 * Name resolution for QL
 */ 



// modeling use occurrences of names
alias Use = rel[loc use, str name];

// modeling declaring occurrences of names
alias Def = rel[str name, loc def];

alias UseDef = rel[loc use, loc def];

// the reference graph
alias RefGraph = tuple[
  Use uses, 
  Def defs, 
  UseDef useDef
]; 

RefGraph resolve(AForm f) = <us, ds, us o ds>
  when Use us := uses(f), Def ds := defs(f);
  
RefGraph resolve(AForm f) {
	definitions = gefs(f);
	references = uses(f);
	
	referenced = {ref | ref <- references, ref.def in definitions<def>};
	
	return <referenced, definitions, referenced o definitions>;
}

// Use is set of <loc use, str name>
Use uses(AForm f) {
  return {<u.src, u.name> | /AId u := f};
}

// Def is set of <str name, loc def>
Def defs(AForm f) {
  return {<q.answer_ref.name, q.answer_ref.src> | /AQuestion q := f, q has answer_ref};
}