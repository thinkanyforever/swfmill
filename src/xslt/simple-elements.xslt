<?xml version="1.0"?>
<xsl:stylesheet	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
				xmlns:swft="http://subsignal.org/swfml/swft"
				xmlns:str="http://exslt.org/strings"
				xmlns:math="http://exslt.org/math"
				extension-element-prefixes="swft"
				version='1.0'>

<!-- 
	contains templates for most of the swfml-simple elements 
-->

<!-- basic SWF setup -->
<xsl:template match="movie">
	<!-- set defaults for movie -->
	<xsl:variable name="version">
		<xsl:choose>
			<xsl:when test="@version"><xsl:value-of select="@version"/></xsl:when>
			<xsl:otherwise>7</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="compressed">
		<xsl:choose>
			<xsl:when test="@compressed='true'">1</xsl:when>
			<xsl:when test="@compressed='false'">0</xsl:when>
			<xsl:otherwise>1</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="framerate">
		<xsl:choose>
			<xsl:when test="@framerate"><xsl:value-of select="@framerate"/></xsl:when>
			<xsl:otherwise>12</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="frames">
		<xsl:choose>
			<xsl:when test="@frames"><xsl:value-of select="@frames"/></xsl:when>
			<xsl:otherwise>1</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="left">
		<xsl:choose>
			<xsl:when test="@left"><xsl:value-of select="@left * 20"/></xsl:when>
			<xsl:otherwise>0</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="top">
		<xsl:choose>
			<xsl:when test="@top"><xsl:value-of select="@top * 20"/></xsl:when>
			<xsl:otherwise>0</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="right">
		<xsl:choose>
			<xsl:when test="@width"><xsl:value-of select="$left + (@width * 20)"/></xsl:when>
			<xsl:otherwise>6400</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="bottom">
		<xsl:choose>
			<xsl:when test="@height"><xsl:value-of select="$top + (@height * 20)"/></xsl:when>
			<xsl:otherwise>4800</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>

	<swf version="{$version}" compressed="{$compressed}">
		<Header framerate="{$framerate}" frames="{$frames}">
			<size>
				<Rectangle left="{$left}" right="{$right}" top="{$top}" bottom="{$bottom}"/>
			</size>
			<tags>
				<xsl:apply-templates/>
				<End/>
			</tags>
		</Header>
	</swf>
</xsl:template>

<!-- background color -->
<xsl:template match="background">
	<SetBackgroundColor>
		<color>
			<xsl:call-template name="color"/>
		</color>
	</SetBackgroundColor>
</xsl:template>

<!-- library just passes thru, children decide wether to export by themselves -->
<xsl:template match="library">
	<xsl:apply-templates/>
</xsl:template>

<!-- linkage export -->
<xsl:template match="@id" mode="export">
	<xsl:param name="id"/>
	<Export count="1">
		<symbols>
			<Symbol objectID="{$id}">
				<xsl:attribute name="name"><xsl:value-of select="."/></xsl:attribute>
			</Symbol>
		</symbols>
	</Export>
</xsl:template>
<xsl:template match="@*" mode="export" priority="-1"/>

<!-- place -->
<xsl:template match="place">
	<xsl:variable name="id">
		<xsl:value-of select="swft:map-id(@id)"/>
	</xsl:variable>
	<xsl:variable name="x">
		<xsl:choose>
			<xsl:when test="@x"><xsl:value-of select="@x * 20"/></xsl:when>
			<xsl:otherwise>0</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="y">
		<xsl:choose>
			<xsl:when test="@y"><xsl:value-of select="@y * 20"/></xsl:when>
			<xsl:otherwise>0</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="scale">
		<xsl:choose>
			<xsl:when test="@scale"><xsl:value-of select="@scale"/></xsl:when>
			<xsl:otherwise>1</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="depth"><xsl:value-of select="@depth"/></xsl:variable>
	
	<!-- if we have a former place with the same depth, use morph="1" replace="0"
		 using morph="0" and replace="1" only works for the same objectID
		 that is already placed in layer (depth) -->
	<xsl:variable name="replace">
		<xsl:choose>
			<xsl:when test="preceding-sibling::place[@depth=$depth] or ../preceding-sibling::frame/place[@depth=$depth]">1</xsl:when>
			<xsl:otherwise>0</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:if test="$replace = '1'">
		<RemoveObject2 depth="{@depth}"/>
	</xsl:if>
	<PlaceObject2 replace="0" morph="{$replace}" depth="{$depth}" objectID="{$id}" name="{@name}">
		<xsl:if test="*">
			<!-- 0x200: initialize -->
			<xsl:attribute name="allflags1">0x200</xsl:attribute>
			<events>
				<Event flags1="0x200">
					<actions>
						<xsl:apply-templates mode="set"/>
						<EndAction/>
					</actions>
				</Event>
				<Event/>
			</events>
		</xsl:if>
		<transform>
			<Transform transX="{$x}" transY="{$y}" scaleX="{$scale}" scaleY="{$scale}"/>
		</transform>
	</PlaceObject2>
</xsl:template>


<!-- transform -->
<xsl:template match="transform">
	<xsl:variable name="id">
		<xsl:value-of select="swft:map-id(@id)"/>
	</xsl:variable>
	<xsl:variable name="myid">
		<xsl:value-of select="@id"/>
	</xsl:variable>
	<xsl:variable name="x">
		<xsl:choose>
			<xsl:when test="@x"><xsl:value-of select="@x * 20"/></xsl:when>
			<xsl:otherwise>0</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="y">
		<xsl:choose>
			<xsl:when test="@y"><xsl:value-of select="@y * 20"/></xsl:when>
			<xsl:otherwise>0</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="scale">
		<xsl:choose>
			<xsl:when test="@scale"><xsl:value-of select="@scale"/></xsl:when>
			<xsl:otherwise>1</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="depth">
		<xsl:value-of select="preceding-sibling::place[@id=$myid]/@depth"/>
	</xsl:variable>
	
	<PlaceObject2 replace="1" depth="{$depth}" objectID="{$id}">
		<transform>
			<Transform transX="{$x}" transY="{$y}" scaleX="{$scale}" scaleY="{$scale}"/>
		</transform>
	</PlaceObject2>
</xsl:template>

<!-- textfield -->
<xsl:template match="textfield">
	<xsl:variable name="id">
		<xsl:value-of select="swft:map-id(@id)"/>
	</xsl:variable>
	<xsl:variable name="x">
		<xsl:choose>
			<xsl:when test="@x"><xsl:value-of select="@x * 20"/></xsl:when>
			<xsl:otherwise>0</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="y">
		<xsl:choose>
			<xsl:when test="@y"><xsl:value-of select="@y * 20"/></xsl:when>
			<xsl:otherwise>0</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="width">
		<xsl:choose>
			<xsl:when test="@width"><xsl:value-of select="@width * 20"/></xsl:when>
			<xsl:otherwise>100</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="height">
		<xsl:choose>
			<xsl:when test="@height"><xsl:value-of select="@height * 20"/></xsl:when>
			<xsl:otherwise>100</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="size">
		<xsl:choose>
			<xsl:when test="@size"><xsl:value-of select="@size * 20"/></xsl:when>
			<xsl:otherwise>240</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>

	<DefineEditText objectID="{$id}" wordWrap="1" multiLine="1" password="0" 
		readOnly="0" autoSize="0" hasLayout="1"
		notSelectable="0" hasBorder="0" isHTML="0" useOutlines="1" 
		fontRef="{swft:map-id(@font)}" fontHeight="{$size}"
		align="0" leftMargin="0" rightMargin="0" indent="0" leading="40" 
		variableName="{@name}" initialText="{@text}">
		<size>
			<Rectangle left="{$x}" right="{$x + $width}" top="{$y}" bottom="{$y + $height}"/>
		</size>
		<color>
			<xsl:call-template name="color-rgba"/>
		</color>
	</DefineEditText>

</xsl:template>

<!-- video object -->
<xsl:template match="video">
	<xsl:variable name="id">
		<xsl:choose>
			<xsl:when test="@id">
				<xsl:value-of select="swft:map-id(@id)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="swft:next-id()"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="frames">
		<xsl:choose>
			<xsl:when test="@frames"><xsl:value-of select="@frames"/></xsl:when>
			<xsl:otherwise>0</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="width">
		<xsl:choose>
			<xsl:when test="@width"><xsl:value-of select="@width"/></xsl:when>
			<xsl:otherwise>160</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="height">
		<xsl:choose>
			<xsl:when test="@height"><xsl:value-of select="@height"/></xsl:when>
			<xsl:otherwise>120</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="deblocking">
		<xsl:choose>
			<xsl:when test="@deblocking"><xsl:value-of select="@deblocking"/></xsl:when>
			<xsl:otherwise>0</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="smoothing">
		<xsl:choose>
			<xsl:when test="@smoothing">1</xsl:when>
			<xsl:otherwise>0</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="codec">
		<xsl:choose>
			<xsl:when test="@codec"><xsl:value-of select="@codec"/></xsl:when>
			<xsl:otherwise>0</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<DefineVideoStream objectID="{$id}" frames="{$frames}" width="{$width}" height="{$height}" deblocking="{$deblocking}" smoothing="{$smoothing}" codec="{$codec}"/>
</xsl:template>

<!-- frame -->
<xsl:template match="frame">
	<xsl:apply-templates/>
	<xsl:if test="@name">
		<FrameLabel label="{@name}"/>
	</xsl:if>
	<ShowFrame/>
</xsl:template>


<!-- generic clip (w/o @import, these are handled in simple-import.xslt) -->
<xsl:template match="clip" priority="-1">
	<xsl:variable name="id">
		<xsl:choose>
			<xsl:when test="@id">
				<xsl:value-of select="swft:map-id(@id)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="swft:next-id()"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<DefineSprite objectID="{$id}" frames="1">
		<tags>
			<xsl:apply-templates/>
			<End/>
		</tags>
	</DefineSprite>	
	<xsl:if test="ancestor::library">
		<xsl:apply-templates select="*|@*" mode="export">
			<xsl:with-param name="id"><xsl:value-of select="$id"/></xsl:with-param>
		</xsl:apply-templates>
	</xsl:if>
	<xsl:if test="@class">
		<xsl:call-template name="register-class">
			<xsl:with-param name="class" select="@class"/>
			<xsl:with-param name="linkage-id" select="@id"/>
		</xsl:call-template>
	</xsl:if>
</xsl:template>


<!-- stop -->
<xsl:template match="stop">
	<DoAction>
		<actions>
			<Stop/>
			<EndAction/>
		</actions>
	</DoAction>
</xsl:template>


<!-- call -->
<xsl:template match="call">
	<xsl:variable name="object">
		<xsl:choose>
			<xsl:when test="@object"><xsl:value-of select="@object"/></xsl:when>
			<xsl:otherwise>Main</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="method">
		<xsl:choose>
			<xsl:when test="@method"><xsl:value-of select="@method"/></xsl:when>
			<xsl:otherwise>main</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="spriteid">
		<xsl:value-of select="swft:next-id()"/>
	</xsl:variable>
	<DefineSprite objectID="{$spriteid}" frames="1">
		<tags>
			<End/>
		</tags>
	</DefineSprite>
	<Export>
		<symbols>
			<Symbol objectID="{$spriteid}" name="__Packages.swfmill.call.{$object}.{$method}"/>
		</symbols>
	</Export>
	<DoInitAction sprite="{$spriteid}">
		<actions>
			<PushData>
				<items>
					<StackString value="{@object}"/>
				</items>
			</PushData>
			<GetVariable/>
			<PushData>
				<items>
					<StackString value="{@method}"/>
				</items>
			</PushData>
			<CallMethod/>
			<Pop/>
			<EndAction/>
		</actions>
	</DoInitAction>
</xsl:template>


</xsl:stylesheet>