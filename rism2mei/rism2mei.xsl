<?xml version="1.0" encoding="UTF-8"?>

<!--
	
	rism2mei.xsl - XSLT (1.0) stylesheet for transformation of RISM MARC XML to MEI header XML
	
	Laurent Pugin <laurent.pugin@rism-ch.org>
	Swiss RISM Office
	Written: 2010-07-07
	Last modified: 2011-02-22
	
	For info on MARC XML, see http://www.loc.gov/marc/marcxml.html
	For info on the MEI header, see http://music-encoding.org
	For info on RISM, see http://www.rism-ch.org
	
	Based very partially on:
	
	http://oreo.grainger.uiuc.edu/stylesheets/MARC_TEI-twc.xsl
	
	AND
	
	marc2tei.xsl - XSLT (2.0) stylesheet for transformation of MARC XML to TEI header XML (TEI P4)
	Greg Murray <gpm2a@virginia.edu> / Digital Library Production Services, University of Virginia Library
	
-->

<xsl:stylesheet version="1.0" xmlns:marc="http://www.loc.gov/MARC21/slim"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.music-encoding.org/ns/mei">

	<xsl:output method="xml" encoding="UTF-8" indent="yes" media-type="text/xml"/>

	<!-- PARAMETERS -->
	<xsl:param name="header_only">false</xsl:param>
	<!-- true | false -->
	<xsl:param name="agency">Swiss RISM Office</xsl:param>
	<!-- true | false -->
	<xsl:param name="agency_code">CH-BeSRO</xsl:param> <!-- could also be taken from 003 -->


	<!-- ======================================================================= -->
	<!-- UTILITIES                                                               -->
	<!-- ======================================================================= -->

	<xsl:template name="datafield">
		<xsl:param name="tag"/>
		<xsl:param name="ind1">
			<xsl:text> </xsl:text>
		</xsl:param>
		<xsl:param name="ind2">
			<xsl:text> </xsl:text>
		</xsl:param>
		<xsl:param name="subfields"/>
		<xsl:element name="datafield">
			<xsl:attribute name="tag">
				<xsl:value-of select="$tag"/>
			</xsl:attribute>
			<xsl:attribute name="ind1">
				<xsl:value-of select="$ind1"/>
			</xsl:attribute>
			<xsl:attribute name="ind2">
				<xsl:value-of select="$ind2"/>
			</xsl:attribute>
			<xsl:copy-of select="$subfields"/>
		</xsl:element>
	</xsl:template>

	<xsl:template name="subfieldSelect">
		<xsl:param name="codes"/>
		<xsl:param name="delimeter">
			<xsl:text> </xsl:text>
		</xsl:param>
		<xsl:param name="element"/>
		<xsl:if test="string-length($element)>0">
			<xsl:text disable-output-escaping="yes">&lt;</xsl:text>
			<xsl:value-of select="$element"/>
			<xsl:text disable-output-escaping="yes">&gt;</xsl:text>
		</xsl:if>
		<xsl:variable name="str">
			<xsl:for-each select="marc:subfield">
				<xsl:if test="contains($codes, @code)">
					<xsl:value-of select="text()"/>
					<xsl:value-of select="$delimeter"/>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:value-of select="substring($str,1,string-length($str)-string-length($delimeter))"/>
		<xsl:if test="string-length($element)>0">
			<xsl:text disable-output-escaping="yes">&lt;/</xsl:text>
			<xsl:value-of select="$element"/>
			<xsl:text disable-output-escaping="yes">&gt;</xsl:text>
		</xsl:if>
	</xsl:template>

	<xsl:template name="buildSpaces">
		<xsl:param name="spaces"/>
		<xsl:param name="char">
			<xsl:text> </xsl:text>
		</xsl:param>
		<xsl:if test="$spaces>0">
			<xsl:value-of select="$char"/>
			<xsl:call-template name="buildSpaces">
				<xsl:with-param name="spaces" select="$spaces - 1"/>
				<xsl:with-param name="char" select="$char"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>

	<xsl:template name="chopPunctuation">
		<xsl:param name="chopString"/>
		<xsl:variable name="length" select="string-length($chopString)"/>
		<xsl:choose>
			<xsl:when test="$length=0"/>
			<xsl:when test="contains('.:,;/ ', substring($chopString,$length,1))">
				<xsl:call-template name="chopPunctuation">
					<xsl:with-param name="chopString" select="substring($chopString,1,$length - 1)"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="not($chopString)"/>
			<xsl:otherwise>
				<xsl:value-of select="$chopString"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="chopPunctuationFront">
		<xsl:param name="chopString"/>
		<xsl:variable name="length" select="string-length($chopString)"/>
		<xsl:choose>
			<xsl:when test="$length=0"/>
			<xsl:when test="contains('.:,;/[ ', substring($chopString,1,1))">
				<xsl:call-template name="chopPunctuationFront">
					<xsl:with-param name="chopString" select="substring($chopString,2,$length - 1)"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="not($chopString)"/>
			<xsl:otherwise>
				<xsl:value-of select="$chopString"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>


	<!-- ======================================================================= -->
	<!-- GLOBAL VARIABLES                                                        -->
	<!-- ======================================================================= -->

	<xsl:variable name="newline">
		<xsl:text></xsl:text>
	</xsl:variable>

	<!-- ======================================================================= -->
	<!-- TOP-LEVEL TEMPLATE                                                      -->
	<!-- ======================================================================= -->


	<xsl:template match="/">
		<xsl:choose>
			<xsl:when test="//marc:record">
				<xsl:apply-templates select="//marc:record[1]"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:message>rism2mei.xsl: ERROR: No records found.</xsl:message>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="marc:record">
		<xsl:choose>
			<xsl:when test="$header_only = 'true'">
				<xsl:call-template name="meihead"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="mei"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- ======================================================================= -->
	<!-- MAIN OUTPUT TEMPLATE                                                    -->
	<!-- ======================================================================= -->

	<xsl:template name="meihead">
		<xsl:variable name="leader" select="marc:leader"/>
		<xsl:variable name="leader6" select="substring($leader,7,1)"/>
		<xsl:variable name="leader7" select="substring($leader,8,1)"/>
		<xsl:variable name="controlField005" select="marc:controlfield[@tag='005']"/>
		<xsl:variable name="controlField008" select="marc:controlfield[@tag='008']"/>
		<xsl:element name="meihead">
			<xsl:element name="filedesc">

				<!-- titlestmt -->
				<xsl:element name="titlestmt">
					<!-- title for electronic text (240 and 245) -->
					<xsl:apply-templates select="marc:datafield[@tag='240' or @tag='245']"/>
					<!-- author(s) (100 and 110) -->
					<xsl:apply-templates select="marc:datafield[@tag='100' or @tag='110']"/>
					<!-- other respstmt(s) (700 and 710) -->
					<xsl:apply-templates select="marc:datafield[@tag='700' or @tag='710']"/>
				</xsl:element>

				<!-- edtstmt -->
				<!-- UNUSED -->

				<!-- extent -->
				<!-- UNUSED -->

				<!-- pubstmt -->
				<xsl:element name="pubstmt">
					<xsl:call-template name="pubstmt"/>
					<!-- ID -->
					<xsl:apply-templates select="marc:controlfield[@tag='001']"/>
				</xsl:element>

				<!-- seriesstmt -->
				<!-- UNUSED -->

				<!-- notesstmt-->
				<xsl:variable name="notes"
					select="marc:datafield[@tag='500' or @tag='505' or @tag='506' or @tag='510' or @tag='520' or @tag='525' or @tag='533' or @tag='541' or @tag='545' or @tag='546' or @tag='555' or @tag='561' or @tag='563' or @tag='580' or @tag='591' or @tag='594' or @tag='595' or @tag='596' or @tag='597' or @tag='598']"/>
				<xsl:variable name="musicPresentation" select="datafield[@tag='254']"/>
				<xsl:variable name="plateNumber" select="datafield[@tag='028']"/>
				<xsl:if test="$notes or $musicPresentation or $plateNumber">
					<notesstmt>
						<xsl:apply-templates select="$notes"/>
						<xsl:apply-templates select="$musicPresentation"/>
						<xsl:apply-templates select="$plateNumber"/>
					</notesstmt>
				</xsl:if>

				<!-- sourcedesc -->
				<xsl:element name="sourcedesc">
					<!-- test if we have tags with $3 - if no, we have a single source -->
					<xsl:if test="count(//marc:subfield[@code='3'])=0">
						<xsl:element name="source">
							<xsl:apply-templates select="marc:datafield[@tag='260' or @tag='300']" mode="single_material"/>
							<xsl:element name="notesstmt">
								<xsl:apply-templates select="marc:datafield[@tag='590' or @tag='592' or @tag='593']" mode="single_material"/>
							</xsl:element>
						</xsl:element>
					</xsl:if>
					<!-- otherwise, group by material - WARNING: if we got one tag with $3, all the tags WITHOUT $3 won't be converted; TO BE IMROVED -->
					<xsl:apply-templates select="marc:datafield[@tag='260' or @tag='300' or @tag='590' or @tag='592' or @tag='593']"/>
				</xsl:element>	
				
			</xsl:element>
			
			<!-- profiledesc -->
			<xsl:element name="profiledesc">
				<!-- creation -->
				<xsl:variable name="creation_note" select="marc:datafield[@tag='508']"/>
				<xsl:if test="$creation_note">
					<creation>
						<xsl:apply-templates select="$creation_note"/>
					</creation>
				</xsl:if>
				<!-- classification -->
				<xsl:variable name="classification" select="marc:datafield[@tag='650' or @tag='651' or @tag='653' or @tag='657']"/>
				<xsl:if test="$classification">
					<classification>
						<classcode xml:id="RISM_Keyword"/>
						<classcode xml:id="RISM_Place"/>
						<classcode xml:id="RISM_Role"/>
						<classcode xml:id="RISM_Liturgical_Feast"/>
						<keywords>
							<xsl:apply-templates select="$classification"/>
						</keywords>
					</classification>
				</xsl:if>
				<!-- eventlist -->
				<xsl:variable name="events" select="marc:datafield[@tag='511' or @tag='518']"/>
				<xsl:if test="$events">
					<eventlist>
						<xsl:apply-templates select="$events"/>
					</eventlist>
				</xsl:if>		
			</xsl:element>
			
		</xsl:element>
	</xsl:template>

	<!-- ======================================================================= -->
	<!-- OUTPUT TEMPLATE FOR <MEI> DOCUMENT                                  	   -->
	<!-- ======================================================================= -->

	<xsl:template name="mei">
		<mei xmlns="http://www.music-encoding.org/ns/mei"
			xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
			xsi:schemaLocation="http://www.music-encoding.org/ns/mei http://music-encoding.org/mei/schemata/2010-05/xsd/mei-all.xsd">
		<!--mei xmlns="http://www.music-encoding.org/ns/mei" xmlns:xl="http://www.w3.org/1999/xlink" xmlns:xlink="http://www.w3.org/1999/xlink"-->
			<xsl:call-template name="meihead"/>

			<!-- output minimal body for parsing purposes -->
			<music>
				<!-- eventlist -->
				<xsl:variable name="incipits" select="marc:datafield[@tag='031']"/>
				<xsl:if test="$incipits">
					<body>
						<mdiv>
							<score>
								<xsl:apply-templates select="$incipits"/>
							</score>
						</mdiv>					
					</body>
				</xsl:if>		
			</music>
		</mei>
		<xsl:value-of select="$newline"/>
	</xsl:template>

	<!-- ======================================================================= -->
	<!-- TITLE (130, 240, 245, 246. 730, 740)                                    -->
	<!-- ======================================================================= -->

	<!-- uniform title 130, 240, 730, 740 (subfields a, k, m, n, o, p, r) -->

	<xsl:template match="marc:datafield[@tag='130' or @tag='240' or @tag='730' or @tag='740']">
		<!-- main title: subfield a (non-repeatable) -->
		<title type="uniform">
			<xsl:call-template name="subfieldSelect">
				<xsl:with-param name="codes">a</xsl:with-param>
			</xsl:call-template>
			<!-- test for certain other subfields to append to main value -->
			<!-- some subfields are repeatable, so loop through all -->
			<xsl:for-each
				select="marc:subfield[
				@code='k' or @code='m' or @code='n' or @code='o' or @code='p' or @code='r']">
				<xsl:choose>
					<xsl:when test="@code='r'">
						<!-- subfield r = 'Key for music'; add 'in' -->
						<xsl:text>, in </xsl:text>
						<xsl:value-of select="."/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>, </xsl:text>
						<xsl:value-of select="."/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
		</title>
	</xsl:template>

	<!-- diplomatic title 245, 246 (subfields a, b) -->

	<xsl:template match="marc:datafield[@tag='245']">
		<!-- main title: subfield a (non-repeatable) -->
		<title type="diplomatic">
			<xsl:call-template name="subfieldSelect">
				<xsl:with-param name="codes">ab</xsl:with-param>
			</xsl:call-template>
		</title>
	</xsl:template>

	<!-- ======================================================================= -->
	<!-- AUTHOR (100, 110)                                                       -->
	<!-- ======================================================================= -->

	<xsl:template match="marc:datafield[@tag='100' or @tag='110']">
		<xsl:variable name="tag">
			<xsl:value-of select="@tag"/>
		</xsl:variable>
		<!-- use <author> element -->
		<respstmt>
			<xsl:choose>
				<xsl:when test="$tag='110'">
					<!-- corporate name; use subfield a (non-repeatable) -->
					<corpname>
						<xsl:value-of select="marc:subfield[@code='a']"/>
					</corpname>
				</xsl:when>
				<xsl:otherwise>
					<!-- personal name -->
					<persname>
						<xsl:value-of select="marc:subfield[@code='a']"/>
					</persname>
				</xsl:otherwise>
			</xsl:choose>
		</respstmt>
	</xsl:template>

	<!-- ======================================================================= -->
	<!-- RESPSTMT (700, 710)                                                     -->
	<!-- ======================================================================= -->

	<xsl:template match="marc:datafield[@tag='700' or @tag='710']">
		<xsl:variable name="tag">
			<xsl:value-of select="@tag"/>
		</xsl:variable>
		<!-- use <author> element -->
		<respstmt>
			<xsl:choose>
				<xsl:when test="$tag='710'">
					<!-- corporate name; use subfield a (non-repeatable) -->
					<corpname>
						<xsl:value-of select="marc:subfield[@code='a']"/>
						<xsl:apply-templates select="marc:subfield[@code='4']" mode="respstmt"/>
					</corpname>
				</xsl:when>
				<xsl:otherwise>
					<!-- personal name -->
					<persname>
						<xsl:value-of select="marc:subfield[@code='a']"/>
					</persname>
					<xsl:apply-templates select="marc:subfield[@code='4']" mode="respstmt"/>
				</xsl:otherwise>
			</xsl:choose>
		</respstmt>
	</xsl:template>

	<!-- relator codes for 700 and 710 -->

	<xsl:template match="marc:subfield[@code='4']" mode="respstmt">
		<resp>
			<xsl:variable name="code">
				<xsl:value-of select="."/>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="$code = 'arr'">arranger</xsl:when>
				<xsl:when test="$code = 'art'">artist</xsl:when>
				<xsl:when test="$code = 'asn'">associated name</xsl:when>
				<xsl:when test="$code = 'aut'">author</xsl:when>
				<xsl:when test="$code = 'bnd'">binder</xsl:when>
				<xsl:when test="$code = 'bsl'">bookseller</xsl:when>
				<xsl:when test="$code = 'ccp'">conceptor</xsl:when>
				<xsl:when test="$code = 'chr'">choreographer</xsl:when>
				<xsl:when test="$code = 'clb'">collaborator</xsl:when>
				<xsl:when test="$code = 'cmp'">composer</xsl:when>
				<xsl:when test="$code = 'cnd'">conductor</xsl:when>
				<xsl:when test="$code = 'cns'">censor</xsl:when>
				<xsl:when test="$code = 'com'">compiler</xsl:when>
				<xsl:when test="$code = 'cst'">costume designer</xsl:when>
				<xsl:when test="$code = 'dnc'">dancer</xsl:when>
				<xsl:when test="$code = 'dnr'">donor</xsl:when>
				<xsl:when test="$code = 'dte'">dedicatee</xsl:when>
				<xsl:when test="$code = 'dub'">dubious</xsl:when>
				<xsl:when test="$code = 'edt'">editor</xsl:when>
				<xsl:when test="$code = 'egr'">engraver</xsl:when>
				<xsl:when test="$code = 'fmo'">former owner</xsl:when>
				<xsl:when test="$code = 'ill'">illustrator</xsl:when>
				<xsl:when test="$code = 'itr'">instrumentalist</xsl:when>
				<xsl:when test="$code = 'lbt'">librettist</xsl:when>
				<xsl:when test="$code = 'ltg'">lithograph</xsl:when>
				<xsl:when test="$code = 'lyr'">lyricist</xsl:when>
				<xsl:when test="$code = 'otm'">event organizer</xsl:when>
				<xsl:when test="$code = 'pat'">patron</xsl:when>
				<xsl:when test="$code = 'pbl'">publisher</xsl:when>
				<xsl:when test="$code = 'ppm'">paper maker</xsl:when>
				<xsl:when test="$code = 'prd'">production personnel</xsl:when>
				<xsl:when test="$code = 'prf'">performer</xsl:when>
				<xsl:when test="$code = 'prt'">printer</xsl:when>
				<xsl:when test="$code = 'scr'">scribe</xsl:when>
				<xsl:when test="$code = 'trl'">translater</xsl:when>
				<xsl:when test="$code = 'voc'">vocalist</xsl:when>
				<xsl:otherwise>[unknown]</xsl:otherwise>
			</xsl:choose>
		</resp>
	</xsl:template>

	<!-- ======================================================================= -->
	<!-- PUBSTMT (001, 005)                                                      -->
	<!-- ======================================================================= -->

	<xsl:template name="pubstmt">
		<!-- use <author> element -->
		<respstmt>
			<corpname>
				<xsl:value-of select="$agency"/>
				<identifier type="MarcOrganizationCode"><xsl:value-of select="$agency_code"/></identifier>
			</corpname>
		</respstmt>
		<xsl:variable name="pubdate" select="substring(marc:controlfield[@tag='005'],1,8)"/>
		<xsl:variable name="year" select="substring($pubdate,1,4)"/>
		<xsl:variable name="month" select="substring($pubdate,5,2)"/>
		<xsl:variable name="day" select="substring($pubdate,7,2)"/>
		<date>
			<xsl:value-of select="concat($year,'-',$month,'-',$day)"/>
		</date>
	</xsl:template>

	<xsl:template match="marc:controlfield[@tag='001']">
		<!-- main title: subfield a (non-repeatable) -->
		<identifier type="rism_id">
			<xsl:value-of select="."/>
		</identifier>
	</xsl:template>

	<!-- ======================================================================= -->
	<!-- NOTESSTMT (028, 254, 5xx)                                                     -->
	<!-- ======================================================================= -->

	<!-- music presentation (254) -->
	<xsl:template match="marc:datafield[@tag='254']">
		<xsl:variable name="tag" select="@tag"/>
		<annot type="musical_presentation" n="{$tag}">
			<xsl:call-template name="subfieldSelect">
				<xsl:with-param name="codes">a</xsl:with-param>
			</xsl:call-template>
		</annot>
	</xsl:template>
	
	<!-- plate number (028) -->	
	<xsl:template match="marc:datafield[@tag='028']">
		<xsl:variable name="tag" select="@tag"/>
		<annot type="plate_number" n="{$tag}">
			<xsl:call-template name="subfieldSelect">
				<xsl:with-param name="codes">a</xsl:with-param>
			</xsl:call-template>
		</annot>
	</xsl:template>
	
	<!-- notes (5XX) -->
	<xsl:template
		match="marc:datafield[@tag='500' or @tag='505' or @tag='506' or @tag='510' or @tag='520' or @tag='525' or @tag='533' or @tag='541' or @tag='545' or @tag='546' or @tag='555' or @tag='561' or @tag='563' or @tag='580' or @tag='591' or @tag='595' or @tag='596' or @tag='597' or @tag='598']">
		<xsl:variable name="tag" select="@tag"/>
		<xsl:variable name="annottype">
			<xsl:choose>
				<xsl:when test="$tag = '500'">general</xsl:when>
				<xsl:when test="$tag = '505'">content</xsl:when>
				<xsl:when test="$tag = '506'">access</xsl:when>
				<xsl:when test="$tag = '510'">reference</xsl:when>
				<xsl:when test="$tag = '520'">summary</xsl:when>
				<xsl:when test="$tag = '525'">supplementary_material</xsl:when>
				<xsl:when test="$tag = '533'">reproduction</xsl:when>
				<xsl:when test="$tag = '541'">acquisition</xsl:when>
				<xsl:when test="$tag = '545'">biography</xsl:when>
				<xsl:when test="$tag = '546'">language</xsl:when>
				<xsl:when test="$tag = '555'">aid</xsl:when>
				<xsl:when test="$tag = '561'">provenance</xsl:when>
				<xsl:when test="$tag = '563'">binding</xsl:when>
				<xsl:when test="$tag = '580'">linking</xsl:when>
				<xsl:when test="$tag = '591'">olim</xsl:when>
				<xsl:when test="$tag = '595'">roles</xsl:when>
				<xsl:when test="$tag = '596'">rism_reference</xsl:when>
				<xsl:when test="$tag = '597'">binding</xsl:when>
				<xsl:when test="$tag = '598'">original_parts</xsl:when>
				<xsl:otherwise>[unspecified]</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<annot type="{$annottype}" n="{$tag}">
			<xsl:choose>
				<xsl:when test="$tag='541'">
					<xsl:call-template name="subfieldSelect">
						<xsl:with-param name="codes">acd</xsl:with-param>
						<xsl:with-param name="delimeter">, </xsl:with-param>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="$tag='591'">
					<xsl:call-template name="subfieldSelect">
						<xsl:with-param name="codes">a4</xsl:with-param>
						<xsl:with-param name="delimeter">, </xsl:with-param>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="subfieldSelect">
						<xsl:with-param name="codes">a</xsl:with-param>
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
		</annot>
	</xsl:template>

	<!-- scoring information (594) -->
	<xsl:template match="marc:datafield[@tag='594']">
		<xsl:variable name="tag" select="@tag"/>
		<annot type="scoring" n="{$tag}">
			<xsl:variable name="delimeter">
				<xsl:text>; </xsl:text>
			</xsl:variable>
			<!-- cat everything into the $str variable -->
			<xsl:variable name="str">
				<xsl:for-each select="marc:subfield">
					<xsl:variable name="code">
						<xsl:value-of select="@code"/>
					</xsl:variable>
					<xsl:variable name="scoring">
						<xsl:choose>
							<xsl:when test="$code = 'a'">Solo voice</xsl:when>
							<xsl:when test="$code = 'b'">Additional solo voice</xsl:when>
							<xsl:when test="$code = 'c'">Choir voice</xsl:when>
							<xsl:when test="$code = 'd'">Additional choir voice</xsl:when>
							<xsl:when test="$code = 'e'">Soloist intrument</xsl:when>
							<xsl:when test="$code = 'f'">Strings</xsl:when>
							<xsl:when test="$code = 'g'">Woodwinds</xsl:when>
							<xsl:when test="$code = 'h'">Brasses</xsl:when>
							<xsl:when test="$code = 'i'">Plucked instruments</xsl:when>
							<xsl:when test="$code = 'k'">Precussion</xsl:when>
							<xsl:when test="$code = 'l'">Keyboards</xsl:when>
							<xsl:when test="$code = 'm'">Other instruments</xsl:when>
							<xsl:when test="$code = 'n'">Basso continuo</xsl:when>
							<xsl:otherwise>[unspecified]</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<!-- cat the values: -->
					<xsl:value-of select="$scoring"/>
					<xsl:text>: </xsl:text>
					<xsl:value-of select="text()"/>
					<xsl:value-of select="$delimeter"/>
				</xsl:for-each>
			</xsl:variable>
			<!-- truncate the last delimiter -->
			<xsl:value-of select="substring($str,1,string-length($str)-string-length($delimeter))"/>
		</annot>
	</xsl:template>
	
	<!-- ======================================================================= -->
	<!-- SOURCEDESC (260, 300, 590, 592, 593)                                    -->
	<!-- ======================================================================= -->

	<!-- key on material subfield $3 -->
	<xsl:key name="material" match="marc:subfield[@code='3']" use="text()" />
	
	<!-- source for tags with $3 and group by $3 -->
	<xsl:template match="marc:datafield[@tag='260' or @tag='300' or @tag='590' or @tag='592' or @tag='593']">
		<!-- group by $3 unsing the key -->
		<xsl:for-each select="./marc:subfield[@code='3'][count(. | key('material', text())[1]) = 1]">
			<xsl:sort select="text()" />
			<xsl:element name="source">
				<!-- go through the list and get the 260 and 300 tags -->
				<xsl:for-each select="key('material', .)/ancestor::node()">
					<xsl:call-template name="source">
						<xsl:with-param name="node" select="."/> 
					</xsl:call-template>
				</xsl:for-each>
				<!-- go through the list again and get the 5XX tags into and notesstmt -->
				<xsl:element name="notesstmt">
					<!-- and an annot for the material set ($3) -->
					<annot type="material_set"><xsl:value-of select="text()"/></annot>
					<xsl:for-each select="key('material', .)/ancestor::node()">
						<xsl:call-template name="source_notesstmt">
							<xsl:with-param name="node" select="."/> 
						</xsl:call-template>
					</xsl:for-each>	
				</xsl:element>
			</xsl:element>
		</xsl:for-each>
	</xsl:template>	
	
	<!-- source for tags without $3 - tags 260 and 300 -->
	<xsl:template match="marc:datafield[@tag='260' or @tag='300']" mode="single_material">
		<xsl:variable name="single_material">
			<xsl:value-of select="count(./marc:subfield[@code='3'])"/>
		</xsl:variable>		
		<xsl:if test="$single_material=0">
			<xsl:call-template name="source">
				<xsl:with-param name="node" select="."/> 
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	
	<!-- source for tags without $3 - tags 5XX within and notesstmt -->
	<xsl:template match="marc:datafield[@tag='590' or @tag='592' or @tag='593']" mode="single_material">
		<xsl:variable name="single_material">
			<xsl:value-of select="count(./marc:subfield[@code='3'])"/>
		</xsl:variable>		
		<xsl:if test="$single_material=0">
			<xsl:call-template name="source_notesstmt">
				<xsl:with-param name="node" select="."/> 
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	
	<!-- do fill the source element - 260 and 300 -->
	<xsl:template name="source">
		<xsl:param name="node"/> 
		<xsl:choose>
			<xsl:when test="$node/@tag='260'">
				<xsl:element name="pubstmt">
					<xsl:call-template name="subfieldSelect">
						<xsl:with-param name="codes">a</xsl:with-param>
						<xsl:with-param name="element">geogname</xsl:with-param>
					</xsl:call-template>
					<xsl:element name="respstmt">
						<xsl:call-template name="subfieldSelect">
							<xsl:with-param name="codes">b</xsl:with-param>
							<xsl:with-param name="element">name</xsl:with-param>
						</xsl:call-template>
					</xsl:element>
					<xsl:call-template name="subfieldSelect">
						<xsl:with-param name="codes">c</xsl:with-param>
						<xsl:with-param name="element">date</xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="subfieldSelect">
						<xsl:with-param name="codes">e</xsl:with-param>
						<xsl:with-param name="element">geogname</xsl:with-param>
					</xsl:call-template>
					<xsl:element name="respstmt">
						<xsl:call-template name="subfieldSelect">
							<xsl:with-param name="codes">f</xsl:with-param>
							<xsl:with-param name="element">name</xsl:with-param>
						</xsl:call-template>
					</xsl:element>
				</xsl:element>
			</xsl:when>
			<xsl:when test="$node/@tag='300'">
				<xsl:element name="physdesc">
					<xsl:call-template name="subfieldSelect">
						<xsl:with-param name="codes">a</xsl:with-param>
						<xsl:with-param name="element">extent</xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="subfieldSelect">
						<xsl:with-param name="codes">b</xsl:with-param>
						<xsl:with-param name="delimeter">; </xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="subfieldSelect">
						<xsl:with-param name="codes">c</xsl:with-param>
						<xsl:with-param name="element">dimensions</xsl:with-param>
					</xsl:call-template>
				</xsl:element>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	
	<!-- do fill the source/notesstmt element - 5XX -->
	<xsl:template name="source_notesstmt">
		<xsl:param name="node"/> 
		<xsl:variable name="tag" select="$node/@tag"/>
		<xsl:choose>
			<xsl:when test="$tag='590' and $node/marc:subfield[@code='a']">
				<annot type="parts" n="{$tag}">
					<xsl:call-template name="subfieldSelect">
						<xsl:with-param name="codes">a</xsl:with-param>
					</xsl:call-template>
				</annot>
				</xsl:when>
				<xsl:when test="$tag='590' and $node/marc:subfield[@code='b']">
				<annot type="missing_parts" n="{$tag}">
					<xsl:call-template name="subfieldSelect">
						<xsl:with-param name="codes">b</xsl:with-param>
					</xsl:call-template>
				</annot>
			</xsl:when>
			<xsl:when test="$tag='592'">
				<annot type="watermark" n="{$tag}">
					<xsl:call-template name="subfieldSelect">
						<xsl:with-param name="codes">a</xsl:with-param>
					</xsl:call-template>
				</annot>
			</xsl:when>
			<xsl:when test="$tag='593'">			
				<annot type="source_type" n="{$tag}">
					<xsl:call-template name="subfieldSelect">
						<xsl:with-param name="codes">a</xsl:with-param>
					</xsl:call-template>
				</annot>
			</xsl:when>			
			</xsl:choose>
	</xsl:template>
	
	<!-- ======================================================================= -->
	<!-- PROFILEDESC (508, 511, 518, 650, 651, 653, 657)                         -->
	<!-- ======================================================================= -->

	<!-- creation note (508) -->
	<xsl:template match="marc:datafield[@tag='508']">
		<xsl:variable name="tag" select="@tag"/>
		<p>
			<xsl:call-template name="subfieldSelect">
				<xsl:with-param name="codes">a</xsl:with-param>
			</xsl:call-template>
		</p>
	</xsl:template>

	<!-- classification (650, 651, 653, 657) -->
	<xsl:template
		match="marc:datafield[@tag='650' or @tag='651' or @tag='653' or @tag='657']">
		<xsl:variable name="tag" select="@tag"/>
		<xsl:variable name="classcode">
			<xsl:choose>
				<xsl:when test="$tag = '650'">RISM_Keyword</xsl:when>
				<xsl:when test="$tag = '651'">RISM_Place</xsl:when>
				<xsl:when test="$tag = '653'">RISM_Role</xsl:when>
				<xsl:when test="$tag = '657'">RISM_Liturgical_Feast</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<term classcode="{$classcode}" n="{$tag}">
			<xsl:call-template name="subfieldSelect">
				<xsl:with-param name="codes">a</xsl:with-param>
			</xsl:call-template>
		</term>
	</xsl:template>
	
	<!-- notes (511, 518) -->
	<xsl:template
		match="marc:datafield[@tag='511' or @tag='518']">
		<xsl:variable name="tag" select="@tag"/>
		<event n="{$tag}">
			<xsl:call-template name="subfieldSelect">
					<xsl:with-param name="codes">a</xsl:with-param>
					<xsl:with-param name="delimeter">; </xsl:with-param>
			</xsl:call-template>
		</event>
	</xsl:template>
	
	<!-- ======================================================================= -->
	<!-- INCIPITS (031)                                                          -->
	<!-- ======================================================================= -->
	
	<!-- creation note (031) -->
	<xsl:template match="marc:datafield[@tag='031']">
		<section n="{./marc:subfield[@code='a']}">
			<staff n="1">
				<layer>
					<tempo staff="1">
						<xsl:call-template name="subfieldSelect">
							<xsl:with-param name="codes">d</xsl:with-param>
						</xsl:call-template>					
					</tempo>
					<dir staff="1">
					<xsl:call-template name="subfieldSelect">
						<xsl:with-param name="codes">t</xsl:with-param>
					</xsl:call-template>	
					</dir>
				</layer>
			</staff>
		</section>
	</xsl:template>

	<!--xsl:apply-templates select="document('http://docs.rism-ch.org/test.xml')"/>
		<xsl:apply-templates/-->

	<xsl:template match="@*|node()">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>


</xsl:stylesheet>
