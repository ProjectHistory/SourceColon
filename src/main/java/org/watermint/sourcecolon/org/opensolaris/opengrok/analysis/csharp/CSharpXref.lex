/*
 * CDDL HEADER START
 *
 * The contents of this file are subject to the terms of the
 * Common Development and Distribution License (the "License").  
 * You may not use this file except in compliance with the License.
 *
 * See LICENSE.txt included in this distribution for the specific
 * language governing permissions and limitations under the License.
 *
 * When distributing Covered Code, include this CDDL HEADER in each
 * file and include the License file at LICENSE.txt.
 * If applicable, add the following below this CDDL HEADER, with the
 * fields enclosed by brackets "[]" replaced with your own identifying
 * information: Portions Copyright [yyyy] [name of copyright owner]
 *
 * CDDL HEADER END
 * Portions Copyright (c) 2013 Takayuki Okazaki.
 */

/*
 * Cross reference a C# file
 * @author Christoph Hofmann - ChristophHofmann AT gmx dot de
 */

package org.watermint.sourcecolon.org.opensolaris.opengrok.analysis.csharp;
import org.watermint.sourcecolon.org.opensolaris.opengrok.analysis.JFlexXref;
import java.io.IOException;
import java.io.Writer;
import java.io.Reader;
import org.watermint.sourcecolon.org.opensolaris.opengrok.web.Util;

%%
%public
%class CSharpXref
%extends JFlexXref
%unicode
%ignorecase
%int
%{
  /* Must match WhiteSpace regex */
  private final static String WHITE_SPACE = "[ \t\f\r]+";

  // TODO move this into an include file when bug #16053 is fixed
  @Override
  protected int getLineNumber() { return yyline; }
  @Override
  protected void setLineNumber(int x) { yyline = x; }
%}

/* Must match WHITE_SPACE constant */
WhiteSpace     = [ \t\f\r]+
EOL = \r|\n|\r\n|\u2028|\u2029|\u000B|\u000C|\u0085
Identifier = [a-zA-Z_] [a-zA-Z0-9_]+

URIChar = [\?\+\%\&\:\/\.\@\_\;\=\$\,\-\!\~\*\\]
FNameChar = [a-zA-Z0-9_\-\.]
File = [a-zA-Z]{FNameChar}* "." ([chts]|"cs")
Path = "/"? [a-zA-Z]{FNameChar}* ("/" [a-zA-Z]{FNameChar}*[a-zA-Z0-9])+

Number = (0[xX][0-9a-fA-F]+|[0-9]+\.[0-9]+|[0-9]+)(([eE][+-]?[0-9]+)?[ufdlUFDL]*)?

//ClassName = ({Identifier} ".")* {Identifier}
//ParamName = {Identifier} | "<" {Identifier} ">"

%state  STRING COMMENT SCOMMENT QSTRING VSTRING

%%
<YYINITIAL>{

{Identifier} {
    String id = yytext();
    writeSymbol(id, Consts.kwd, yyline - 1);
}

"<" ({File}|{Path}) ">" {
        out.write("&lt;");
        String path = yytext();
        path = path.substring(1, path.length() - 1);
        out.write("<a href=\""+urlPrefix+"path=");
        out.write(path);
        appendProject();
        out.write("\">");
        out.write(path);
        out.write("</a>");
        out.write("&gt;");
}

/*{Hier}
    { out.write(Util.breadcrumbPath(urlPrefix+"defs=",yytext(),'.'));}
*/
{Number}        { out.write(yytext()); }

 \"     { yybegin(STRING);out.write("\"");}
 \'     { yybegin(QSTRING);out.write("\'");}
 "/*"   { yybegin(COMMENT);out.write("/*");}
 "//"   { yybegin(SCOMMENT);out.write("//");}
}

<STRING> {
 \" {WhiteSpace} \"  { out.write(yytext());}
 \"     { yybegin(YYINITIAL); out.write("\""); }
 \\\\   { out.write("\\\\"); }
 \\\"   { out.write("\\\""); }
}

<QSTRING> {
 "\\\\" { out.write("\\\\"); }
 "\\\'" { out.write("\\\'"); }
 \' {WhiteSpace} \' { out.write(yytext()); }
 \'     { yybegin(YYINITIAL); out.write("'"); }
}

<VSTRING> {
 \" {WhiteSpace} \"  { out.write(yytext());}
 "\"\""   { out.write("\"\""); }
 \"       { yybegin(YYINITIAL); out.write("\""); }
 \\       { out.write("\\"); }
}

<COMMENT> {
"*/"    { yybegin(YYINITIAL); out.write("*/"); }
}

<SCOMMENT> {
  {WhiteSpace}*{EOL} {
    yybegin(YYINITIAL);
    startNewLine();
  }
}

<YYINITIAL, STRING, COMMENT, SCOMMENT, QSTRING, VSTRING> {
"&"     {out.write( "&amp;");}
"<"     {out.write( "&lt;");}
">"     {out.write( "&gt;");}
{WhiteSpace}*{EOL}      { startNewLine(); }
 {WhiteSpace}   { out.write(yytext()); }
 [!-~]  { out.write(yycharat(0)); }
 .      { writeUnicodeChar(yycharat(0)); }
}

<STRING, COMMENT, SCOMMENT, QSTRING, VSTRING> {
{Path}
        { out.write(Util.breadcrumbPath(urlPrefix+"path=",yytext(),'/'));}

{File}
        {
        String path = yytext();
        out.write("<a href=\""+urlPrefix+"path=");
        out.write(path);
        appendProject();
        out.write("\">");
        out.write(path);
        out.write("</a>");}

("http" | "https" | "ftp" ) "://" ({FNameChar}|{URIChar})+[a-zA-Z0-9/]
        {
         String url = yytext();
         out.write("<a href=\"");
         out.write(url);out.write("\">");
         out.write(url);out.write("</a>");}

{FNameChar}+ "@" {FNameChar}+ "." {FNameChar}+
        {
          writeEMailAddress(yytext());
        }
}
