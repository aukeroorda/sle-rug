module Compile

import List;
import AST;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library
// Not documented yet, but source is here:
// https://github.com/usethesource/rascal/blob/master/src/org/rascalmpl/library/lang/html5/DOM.rsc

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTML5Node type and the `str toString(HTML5Node x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */

/* Plan:
	form -> form node, name as page header
	if guard -> add header to fieldset with  <legend>guard</legend>
	questionBlock -> fieldset (add attribute "disabled" to disable all questions inside it)
	
	question -> <label>q.question.name:</label>
  				<input type="text" id="q.answer_ref.nam" name="q.answer_ref.nam"><br><br>
  		with input type dependent on q.answer_type
	
 */
void compile(AForm f) {
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, toString(form2html(f)));
}

HTML5Node form2html(AForm f) {
  return html(
  	head(
  		meta(charset("utf-8")),
		script(src("<f.src[extension="js"].file>"))
  	),
  	body(
  		h1(f.form_id),
  		form(
  			([] | it + ast2html(q) | q <- f.questions)
  		)
  	)
  );
}

str form2js(AForm f) {
	js = "";
	js += collectVars(f);
	js += initForm(f);
	js += updateForm();
	
  	return js;
}

str collectVars(AForm f) {
	vars = "";
	for (/AQuestion q := f, q has answer_ref) {
		vars += "var _<q.answer_ref.name> = <atype2jsdefaultvalue(q.answer_type)>;\n";
	}
	vars += "\n";
	return vars;
}

str initForm(AForm f) {

	inits = "document.addEventListener(\"DOMContentLoaded\", function(event) {\n";
	for (/AQuestion q := f, q has answer_ref) {
		inits += "document.getElementById(\'<q.answer_ref.name>\').value = _<q.answer_ref.name>;\n";
	}
	inits += "});\n";
	return inits;
}



str updateForm() =
	"function update_form() {
	'	var fields = document.getElementsByTagName(\'fieldset\');
	' 	for (var i = 0; i \< fields.length; i++) {
	'		var to_eval = fields[i].dataset.guard + \';\';
	'		fields[i].disabled = !eval(to_eval);
	' 	}
	'}
	'document.addEventListener(\"DOMContentLoaded\", function(event) {
	'	update_form();
	'});
	'";

str atype2jsdefaultvalue(AType a) {
	switch(a) {
	    case string(): return "\"\"";
	    case integer(): return "0";
	    case boolean(): return "false";
	}
}

HTML5Attr getUpdatePolicy(AType a, AQuestion q) {
	switch(a) {
	    case string(): return onchange("_<q.answer_ref.name> = document.getElementById(\'<q.answer_ref.name>\').value; update_form()");
	    case integer(): return onchange("_<q.answer_ref.name> = document.getElementById(\'<q.answer_ref.name>\').value; update_form()");
	    case boolean(): return onchange("_<q.answer_ref.name> = document.getElementById(\'<q.answer_ref.name>\').checked; update_form()");
	}
}

HTML5Node ast2html(AQuestion q) {
	if (q is question) {
		return div(
			[abbr(
				label(q.question, \for(q.answer_ref.name)),
				html5attr("title", q.answer_ref.name)
			 ),
			 br(),
			 input(
			 	atype2html5inputtype(q.answer_type),
			 	id(q.answer_ref.name),
				//oninput("new Function(\'<q.answer_ref.name> = document.getElementById(\'<q.answer_ref.name>\').value;\')();")
				//onchange("_<q.answer_ref.name> = document.getElementById(\'<q.answer_ref.name>\').checked; update_form()")
				getUpdatePolicy(q.answer_type, q)
			 )
			]);
	}
	if(q is computed_question) {
		return div(
			[abbr(
				label(q.question, \for(q.answer_ref.name)),
				html5attr("title", q.answer_ref.name)
			),
			br(),
			input(
				atype2html5inputtype(q.answer_type),
				id(q.answer_ref.name),
				disabled("")
			)
			]);
	}
	if (q is ifthen || q is ifthenelse) {
		list[HTML5Node] nodes = [];
		
		nodes += h3("if <expr2str(q.guard)>");
		HTML5Node fs_then = fieldset(
			( legend("then:")) + 
			( [] | it + ast2html(q) | AQuestion q <- q.then_questions_block.questions) +
			//( id("<q.guard.src>") ) + 
			( html5attr("data-guard", expr2jsexpr(q.guard)) )
		);
		nodes += fs_then;
		
		if (q is ifthenelse) {
			HTML5Node fs_else = fieldset(
				( legend("else:")) + 
				( [] | it + ast2html(q) | AQuestion q <- q.else_questions_block.questions) +
				( html5attr("data-guard", expr2jsexpr(logic_not(q.guard))) )
			);
			nodes += fs_else;
		}
		
		return div(nodes);
	}
	return hr();
}

HTML5Attr atype2html5inputtype(AType a) {
	switch(a) {
	    case string(): return \type("text");
	    case integer(): return \type("number");
	    case boolean(): return \type("checkbox");
	}
}

HTML5Attr atype2html5defaultvalue(AType a) {
	switch(a) {
	    case string(): return \value("");
	    case integer(): return \value(0);
	    case boolean(): return \value(false);
	}
}

str expr2str(AExpr e) {
	switch(e) {
		case ref(id(str s)): return "<s>";
		case \bool(bool b): return "<b>";
		case \str(str s): return "\"<s>\"";
		case \int(int i): return "<i>";
		
		case par(AExpr op):  return "(<expr2str(op)>)";
	    case uplus(AExpr op): return "+<expr2str(op)>";
	    case uminus(AExpr op): return "-<expr2str(op)>";
	    case logic_not(AExpr op): return "!<expr2str(op)>";
	    
	    case mult(AExpr lhs, AExpr rhs): return "<expr2str(lhs)> * <expr2str(rhs)>";
	    case div(AExpr lhs, AExpr rhs): return "<expr2str(lhs)> / <expr2str(rhs)>";
	    case add(AExpr lhs, AExpr rhs): return "<expr2str(lhs)> + <expr2str(rhs)>";
	    case subt(AExpr lhs, AExpr rhs): return "<expr2str(lhs)> - <expr2str(rhs)>";
	    
	    case gt(AExpr lhs, AExpr rhs): return "<expr2str(lhs)> \> <expr2str(rhs)>";
	    case ge(AExpr lhs, AExpr rhs): return "<expr2str(lhs)> \>= <expr2str(rhs)>";
	    case lt(AExpr lhs, AExpr rhs): return "<expr2str(lhs)> \< <expr2str(rhs)>";
	    case le(AExpr lhs, AExpr rhs): return "<expr2str(lhs)> \>= <expr2str(rhs)>";
	    
	    
	    case eq(AExpr lhs, AExpr rhs): return "<expr2str(lhs)> == <expr2str(rhs)>";
	    case neq(AExpr lhs, AExpr rhs): return "<expr2str(lhs)> != <expr2str(rhs)>";
	    
	    case and(AExpr lhs, AExpr rhs): return "<expr2str(lhs)> && <expr2str(rhs)>";
	    case or(AExpr lhs, AExpr rhs): return "<expr2str(lhs)> || <expr2str(rhs)>";    
	}
}

// Guarded every op with parentheses, ids prefixed with underscore
str expr2jsexpr(AExpr e) {
	switch(e) {
		case ref(id(str s)): return "_<s>";
		case \bool(bool b): return "<b>";
		case \str(str s): return "\"<s>\"";
		case \int(int i): return "<i>";
		
		case par(AExpr op):  return "(<expr2jsexpr(op)>)";
	    case uplus(AExpr op): return "(+<expr2jsexpr(op)>)";
	    case uminus(AExpr op): return "(-<expr2jsexpr(op)>)";
	    case logic_not(AExpr op): return "(!<expr2jsexpr(op)>)";
	    
	    case mult(AExpr lhs, AExpr rhs): return "(<expr2jsexpr(lhs)> * <expr2jsexpr(rhs)>)";
	    case div(AExpr lhs, AExpr rhs): return "(<expr2jsexpr(lhs)> / <expr2jsexpr(rhs)>)";
	    case add(AExpr lhs, AExpr rhs): return "(<expr2jsexpr(lhs)> + <expr2jsexpr(rhs)>)";
	    case subt(AExpr lhs, AExpr rhs): return "(<expr2jsexpr(lhs)> - <expr2jsexpr(rhs)>)";
	    
	    case gt(AExpr lhs, AExpr rhs): return "(<expr2jsexpr(lhs)> \> <expr2jsexpr(rhs)>)";
	    case ge(AExpr lhs, AExpr rhs): return "(<expr2jsexpr(lhs)> \>= <expr2jsexpr(rhs)>)";
	    case lt(AExpr lhs, AExpr rhs): return "(<expr2jsexpr(lhs)> \< <expr2jsexpr(rhs)>)";
	    case le(AExpr lhs, AExpr rhs): return "(<expr2jsexpr(lhs)> \>= <expr2jsexpr(rhs)>)";
	    
	    
	    case eq(AExpr lhs, AExpr rhs): return "(<expr2jsexpr(lhs)> == <expr2jsexpr(rhs)>)";
	    case neq(AExpr lhs, AExpr rhs): return "(<expr2jsexpr(lhs)> != <expr2jsexpr(rhs)>)";
	    
	    case and(AExpr lhs, AExpr rhs): return "(<expr2jsexpr(lhs)> && <expr2jsexpr(rhs)>)";
	    case or(AExpr lhs, AExpr rhs): return "(<expr2jsexpr(lhs)> || <expr2jsexpr(rhs)>)";    
	}
}







