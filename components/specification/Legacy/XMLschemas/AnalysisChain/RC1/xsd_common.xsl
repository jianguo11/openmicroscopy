<?xml version="1.0"?>

<!--
	Shared XSD stylesheet items
	
	$Id: xsd_common.xsl 457 2008-06-30 15:08:37Z andrew $
-->

<s:stylesheet  xmlns:s="http://www.w3.org/1999/XSL/Transform" version="1.0">

<!-- ========================================================================
========================================================================== -->		
<s:template match="/">
	<html>
		<head>
			<title>Schema Doc <s:value-of select="$schemaName"/> </title>
			
			<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1"/>
			<meta name="description" content="SchemaDoc generated by Tibco Extensibility xsd stylesheet."/>
			<meta name="copyright" content="Tibco Extensibility 2002"/>
			<link rel="stylesheet" title="Schemadoc Stylesheet" HREF="../schemadoc.css"/>				
			<script language="javascript" src='../sourceutils.js'></script>
			<s:if test="$doImages='true' or $doImages='TRUE'">
				<script language="javascript" src='../svgcheck.js'>&#160;</script>
				<script language="VBScript" src='../svgcheck.vbs'>&#160;</script>
			</s:if>
		</head>
		<body bgcolor="#FFFFFF" marginheight="0" marginwidth="0" topmargin="0" leftmargin="0">
			<s:if test="$doImages='true' or $doImages='TRUE'">
				<!-- removed SVN check -->	 
			</s:if> 	
			<s:apply-templates/>
			
			<center>
				<s:if test="$doSource='true' or $doSource='TRUE'">
				
					<table border="0" WIDTH="90%" BGCOLOR="#eeeeee" >
						<tr>
							<td> 
								<s:apply-templates mode="copy"/>
							</td>
						</tr>
					</table>
				</s:if>			
			</center>
			
		</body>
	</html>
</s:template>

<!-- ========================================================================
	Generate the node path
-->
<s:template match="*" mode="buildLocalPath">

	<s:value-of select="@name" />
	<s:if test="position() != last()">
		<s:choose>
			<s:when test="local-name()='group'">(model group)</s:when>
			<s:when test="local-name()='attributeGroup'">(attribute group)</s:when>
			<s:when test="local-name()='complexType'">(type)</s:when>
		</s:choose>
		
		<s:text>/</s:text>
	</s:if>
	
</s:template>

<!-- ========================================================================
	Dump the list of items doing the using
-->
<s:template mode="applyUsedByList" match="*">
	<a href="{concat('#', generate-id())}"><s:apply-templates select="." mode="generateComponentPath"/></a>
	
	<s:if test="position() != last()">
		<s:text>, </s:text>
	</s:if>
</s:template>

<!-- ========================================================================
	Dump the "used by" list for an element
-->
<s:template name="dumpUsedByRow">
	<s:param name="nodes" />
	<s:param name="title" />
	
	<s:if test="$nodes">
		<tr>
			<td class="tdnames"><s:value-of select="$title" /></td>
			<td class="values" bgcolor="#eeeeee" align="left" valign="top">
				<s:apply-templates mode="applyUsedByList" select="$nodes">
					<s:sort select="@name" />
				</s:apply-templates>
			</td>
		</tr>
	</s:if>
	
</s:template>

<!-- ========================================================================
	Dump the "used by" list for a component
-->
<s:template name="dumpComponentUsedBy">
	<s:param name="refsList" />
	
	<s:variable name="componentName" select="@name" />
	<s:variable name="usingRefs" select="$refsList[@toName=$componentName]" />
	<s:variable name="usingNodes" select="key('gid-key', $usingRefs/@fromId)" />
	
	<s:call-template name="dumpUsedByFromNodes">
		<s:with-param name="usingNodes" select="$usingNodes" />
	</s:call-template>
		
</s:template>

<!-- ========================================================================
Convenience here is that all declared items have a "name" attribute, so we
leverage that to compute the name the same way for all elements.
========================================================================== -->		
<s:template match="*" mode="computePath" >
	<!-- we could, alternately, do this as an apply-template, but this is concise
		and clear -->
	<s:choose>
		<s:when test="local-name()='element'">e:</s:when>
		<s:when test="local-name()='attribute'">a:</s:when>
		<s:when test="local-name()='group'">mg:</s:when>
		<s:when test="local-name()='attributeGroup'">ag:</s:when>
		<s:when test="local-name()='complexType'">t:</s:when>
		<s:when test="local-name()='simpleType'">t:</s:when>
	</s:choose>
	<s:value-of select="@name" />
	<s:if test="position() != last()">/</s:if>
</s:template>

<!-- ========================================================================
========================================================================== -->		
<s:template match = "processing-instruction()" > 
	<s:text >
	</s:text> 
	<s:value-of select = "concat(name(),' : ',.)" /> 
</s:template> 

<!-- ========================================================================
========================================================================== -->		
<s:template name="detailAttributeHeader">
	<tr>
		<th width="15%" class="headers" align="right" valign="top">
			Attribute
		</th>

		<th width="10%" class="headers" align="left" >
			Datatype
		</th>
		<th width="15%" class="headers" align="left" >
			Use
		</th>
		<th width="20%" class="headers" align="left"  >
			Values
		</th>
		<th width="20%" class="headers" align="left" >
			Default
		</th>
		<th width="20%" class="headers" align="left" >
			Comments
		</th>
	</tr>

</s:template>

<!-- ========================================================================
========================================================================== -->		
<s:template match="comment()">
  <s:comment><s:value-of select="."/></s:comment>
</s:template>

<!--
	$Log$
	Revision 1.2  2004/06/10 18:15:54  siah
	[Bug 70] added a namespace

	Revision 1.4  2002/02/06 22:34:10  Eric
	Reenabled schemadoc options, minor improvements...
	
	Revision 1.3  2002/01/17 20:40:39  Eric
	Another round of fixes for schemadoc.
	
	Revision 1.2  2002/01/16 19:20:33  Eric
	Moved shared code, fixed uses in XSD, XSD-CR now in sync.
	
	Revision 1.1  2002/01/15 18:37:42  Eric
	Schemadoc test framework and files.
	
-->

</s:stylesheet>
