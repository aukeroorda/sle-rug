module Transform

import Syntax;
import Resolve;
import AST;
import CST2AST;

/* 
 * Transforming QL forms
 */
 
 
/* Normalization:
 *  wrt to the semantics of QL the following
 *     q0: "" int; 
 *     if (a) { 
 *        if (b) { 
 *          q1: "" int; 
 *        } 
 *        q2: "" int; 
 *      }
 *
 *  is equivalent to
 *     if (true) q0: "" int;
 *     if (true && a && b) q1: "" int;
 *     if (true && a) q2: "" int;
 *
 * Write a transformation that performs this flattening transformation.
 *
 */
 
AForm flatten(AForm f) {

	// First resolve all nested ifthen(else) statements
//	f = outermost visit(f) {
//		case ifthen(
//				outer_guard, 
//				block(
//					ifthen(
//						inner_guard,
//						then_questions_block
//					)
//				)
//			) => ifthen(and(outer_guard, inner_guard), then_questions_block)
//
//		case ifthen(
//				outer_guard,
//				block(
//					ifthenelse(
//						inner_guard,
//						then_questions_block,
//						else_questions_block
//					)
//				)
//			) => ifthen(and(outer_guard, inner_guard), then_questions_block) +
//				 ifthen(not(inner_guard), else_questions_block)
//				 
//		//case ifthenelse(outer_guard, outer_block)
//		
//	}

	AExpr bool_true = \bool(true);
	// flatten questions
	f = form(f.form_id, ([] | it + flatten(q, bool_true) | AQuestion q <- f.questions));

	// Flatten expressions
	f = innermost visit(f) {
		case and(\bool(true), x) => x
		case and(x, \bool(true)) => x
	}
	
	// Lastly ensure all top-level questions are if_then_else-guarded questions
	//f = visit (f) {
	//	case 
	//};
  return f; 
}

list[AQuestion] flatten(AQuestion q, AExpr cond) {
	list[AQuestion] new_qs = [];
	
	if (q is question || q is computed_question) {
		return [ifthen(cond, block([q]))];
	}
	
	
	if (q has then_questions_block) {
		new_qs += ([] | it + flatten(nested_q, and(cond, q.guard)) | nested_q <- q.then_questions_block.questions);
	}
	if (q has else_questions_block) {
		// Note the logic_not() encapsulating the guard
		new_qs += ([] | it + flatten(nested_q, and(cond, logic_not(q.guard))) | nested_q <- q.else_questions_block.questions);
	}
	
	return new_qs;
}

/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */
 
 start[Form] rename(start[Form] f, loc useOrDef, str newName, UseDef useDef) {
 	// First find the source name of the useOrDef
 	// if it is a def, then its already there
 	RefGraph rg = resolve(cst2ast(f));
 	
 	// add the instance we start rename from to set
 	set[loc] to_update = {useOrDef};
 	
 	// find all uses of the name
 	if (useOrDef in rg.uses, <useOrDef, loc d> <- rg.useDef) {
 		// d is definition
 		to_update += {d};
 		// add rest of references to d
 		to_update += { u | <loc u, d> <- rg.useDef };
 	}
 	
 	if (useOrDef in rg.defs) {
 		to_update += { u | <loc u, d> <- rg.useDef };
 	}
 	
 	// rename all uses (include def)
   return visit(f) {
   		case Id x => [Id]newName
   			when x@\loc in to_update
   }; 
 } 
 
 
 

