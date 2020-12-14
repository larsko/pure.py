<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" 
	xmlns:commons="v3.commons.pure.atira.dk" 
	xmlns="v1.publication-import.base-uk.pure.atira.dk"
	xmlns:python="python"
	xmlns:dataField="https://www.inteum.com/technologies/data/" exclude-result-prefixes="python">

<xsl:output method="xml" indent="yes" />

<!-- Passing this from Python -->
<xsl:param name="root_org"/>
<xsl:param name="site"/>

<!-- Locale - not we could grab this from Inteum feed, but this is to make it explicit -->
<xsl:variable name="language" select="'en'" />
<xsl:variable name="country" select="'GB'" />

<!-- Root publications element -->
<xsl:template match="rss/channel">
<publications xmlns="v1.publication-import.base-uk.pure.atira.dk" xmlns:commons="v3.commons.pure.atira.dk">
		<xsl:comment>Pub Date: <xsl:value-of select="pubDate" /></xsl:comment>
		<xsl:apply-templates select="item" />
	</publications>

</xsl:template>

<!-- Matches each patent with an item element -->
<xsl:template match="item">
	
	<patent id="{guid}" subType="innovation">
		<peerReviewed>false</peerReviewed>

		<!--TODO: Parsing date into components using Python, see patents.py for details -->
		<xsl:variable name="year" select="python:get_date(string(pubDate),'Y')" />
		<xsl:variable name="month" select="python:get_date(string(pubDate),'m')" />
		<xsl:variable name="day" select="python:get_date(string(pubDate),'D')" />

		<publicationStatuses>
            <publicationStatus>
                <statusType>published</statusType>
                <date>
                    <commons:year><xsl:value-of select="$year" /></commons:year>
                    <xsl:if test="$month"><commons:month><xsl:value-of select="$month" /></commons:month></xsl:if>
                    <xsl:if test="day"><commons:day><xsl:value-of select="$day" /></commons:day></xsl:if>
                </date>
            </publicationStatus>
        </publicationStatuses>

		<language><xsl:value-of select="$language" />_<xsl:value-of select="$country" /></language>

		<!-- title is a localized string -->
		<title>
			<xsl:call-template name="text">
				<xsl:with-param name="val" select="title" />
			</xsl:call-template>
		</title>
	
		<!-- abstract is a localized string, can contain HTML formatting, so wrap in CDATA -->
		<abstract>
			<xsl:call-template name="text">
				<xsl:with-param name="escape" select="'yes'"/>
				<xsl:with-param name="val">	
			<xsl:text disable-output-escaping="yes">&lt;![CDATA[</xsl:text><xsl:value-of select="python:clean_html(string(description))" disable-output-escaping="no" /><xsl:text disable-output-escaping="yes">]]&gt;</xsl:text>	
				</xsl:with-param>
			</xsl:call-template>
		</abstract>

		<!-- inventors -->
		<persons>
			<xsl:apply-templates select="dataField:inventorList" />
		</persons>

		<!-- related organizations: unspecified -->
		<!--<organisations/>-->

		<!-- Root organization ID - passed by patents.py as external param -->
		<owner id="{$root_org}"/>

		<!-- Keywords: free text only -->
		<xsl:if test="dataField:keywords != ''">
		 <keywords>
            <commons:logicalGroup logicalName="keywordContainers">
                <commons:structuredKeywords>
                    <commons:structuredKeyword>
                    	<commons:freeKeywords>

					 	<xsl:call-template name="split-keywords">
					 		<xsl:with-param name="list" select="dataField:keywords" />
					 	</xsl:call-template>

		 			</commons:freeKeywords>
		 		</commons:structuredKeyword>
		 	</commons:structuredKeywords>
		 </commons:logicalGroup>

		 </keywords>
		 </xsl:if>

		<!-- link to patent page in Inteum system -->
		<urls>
            <url>
                <url><xsl:value-of select="link" /></url>
                <description>
                    <xsl:call-template name="text">
                    	<xsl:with-param name="val" select="'Project page'" />
                    </xsl:call-template>
                </description>
                <type>unspecified</type>
            </url>
        </urls>

        <!-- Visibility of patent -->
        <visibility>Restricted</visibility>

        <!-- Additional IDs -->
        <externalIds>
            <id type="inteum"><xsl:value-of select="dataField:caseId" /></id>
        </externalIds>

	</patent>

</xsl:template>

<!-- Creates list of inventors -->
<xsl:template match="dataField:inventorList">
	
	<xsl:for-each select="dataField:inventor">

		<!-- Try to get a map of person ID from Python -->
		<xsl:variable name="id" select="python:lookup_person(string(dataField:firstName), string(dataField:lastName))" />

		<author>
			<role>inventor</role>
			<person>
				<xsl:if test="$id">
					<xsl:attribute name="id"><xsl:value-of select="$id" /></xsl:attribute>
					<xsl:attribute name="origin">internal</xsl:attribute>
				</xsl:if>
				<firstName><xsl:value-of select="dataField:firstName" /></firstName>
                <lastName><xsl:value-of select="dataField:lastName" /></lastName>
			</person>
		</author>
	</xsl:for-each>

</xsl:template>

<!-- Creates a localized string based on the language and country -->
<xsl:template name="text" >
	<xsl:param name="val" />
	<xsl:param name="escape" select="'no'" />

	<commons:text lang="{$language}" country="{$country}">
		<xsl:choose>
			<xsl:when test="$escape != ''">
				<xsl:value-of disable-output-escaping="yes" select="$val" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$val" />
			</xsl:otherwise>
		</xsl:choose>		
	</commons:text>
	
</xsl:template>

<!-- recursive funtion to build keywords - python might be easier to use instead... -->
<xsl:template name="split-keywords">
  <xsl:param name="list"      select="''" />
  <xsl:param name="separator" select="','" />

  <xsl:if test="not($list = '' or $separator = '')">
    <xsl:variable name="head" select="substring-before(concat($list, $separator), $separator)" />
    <xsl:variable name="tail" select="substring-after($list, $separator)" />

		<commons:freeKeyword>
			<xsl:call-template name="text">
				<xsl:with-param name="val" select="$head" />
			</xsl:call-template>
		</commons:freeKeyword>

    <xsl:call-template name="split-keywords">
      <xsl:with-param name="list"      select="$tail" />
      <xsl:with-param name="separator" select="$separator" />
    </xsl:call-template>
  </xsl:if>
</xsl:template>

</xsl:transform>