{smcl}
{* *! * version 1.0  AH 27 Dec 2021 }{...}
{viewerdialog postsave "dialog postsave"}{...}
{viewerjumpto "Syntax" "postsave##syntax"}{...}
{viewerjumpto "Description" "postsave##description"}{...}
{viewerjumpto "Options" "postsave##options"}{...}
{viewerjumpto "Examples" "postsave##examples"}{...}
{p2colset 1 15 20 2}{...}
{p2col:{bf:[T] postsave} {hline 2}} Saves labeled and formatted postestimation estimates stored in `r(table)' {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 18 2}
{cmdab:postsave [varlist] } 
[{cmd:,}
{it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Main}
{synopt:{opt save(filepath)}}saves table {p_end}
{synopt:{opt append(filepath)}}appends table {p_end}
{synopt:{opt merge(filepath)}}merges table based on var {p_end}
{synopt:{opt mergeid(varlist)}}merges table based on mergid if merge is specified {p_end}
{synopt:{opt sort(varlist)}} sorts by varlist {p_end}
{synopt:{opt eform}} Exponentiates coefficients {p_end}
{synopt:{opt drop(varlist)}} drops variables specified in varlist {p_end}
{synopt:{opt keep(varlist)}} keeps variables specified in varlist {p_end}
{synopt:{opt baselevels(filepath)}}displays baselevels {p_end}
{synopt:{opt baselabel(string)}}labels estimate with string (default ref.) {p_end}
{synopt:{opt heading}}adds row with variable label for categorial variables in varlist {p_end}
{synopt:{opt dropcoef:ficient(string)}} loops over word in string and drops coefficients matching regular expression {p_end}
{synopt:{opt name(string)}} adds variable name set to string {p_end}
{synopt:{opt number(integer)}} adds variable number set to integer {p_end}
{synopt:{opt collab(string)}} adds column lab {p_end}
{synopt:{opt estlab(string)}} adds estimate label {p_end}
{synopt:{opt clean}} list clean table {p_end}

{syntab:Format}

{synopt:{opt format(string)}}Formats estimates according to Stata format specified in string{p_end}
{synopt:{opt labelf:ormat(string)}}format label column according to Stata format specified in string{p_end}
{synopt:{opt cisep:arator(string)}}string separating lower and upper bound of confidence interval, (default="-"){p_end}
{synopt:{opt brackets}}replaces parentheses with brackets{p_end}
{synopt:{opt midpoint}}use midpoint as decimal point separator{p_end}
{synopt:{opt ind:ent(integer)}}indent labels by the number of blanks specified, (default=2){p_end}

{syntab:Advanced}
{synopt:{opt varsu:ffix(string)}}rename all variables in table except label and var with suffix{p_end}

{marker description}{...}
{title:Description}

{pstd}
{opt postsave} list, saves and appends labeled and formatted estimates stored in `r(table)' 

{marker examples}{...}
{title:Examples}

    Setup	
{phang}{cmd:. webuse nlswork}{p_end}
{phang}{cmd:. mixed ln_wage i.race##i.year }{p_end}
{phang}{cmd:. contrast race, effect }{p_end}
{phang}{cmd:. matrix list r(table) }{p_end}

    List formatted regression output 
{phang}{cmd:. postsave race, ciseparator(" to ") }{p_end}
{phang}{cmd:. postsave race, ciseparator(" to ") baselevels heading clean }{p_end}
  		 
{marker author}{...}
{title:Author}
{pstd}
Andreas Haas, Email: andreas.haas@ispm.unibe.ch
