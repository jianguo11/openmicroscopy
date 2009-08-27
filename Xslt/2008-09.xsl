<?xml version = "1.0" encoding = "UTF-8"?>
<!--
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Copyright (C) 2009 Glencoe Software, Inc.
#
#    This library is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser General Public
#    License as published by the Free Software Foundation; either
#    version 2.1 of the License, or (at your option) any later version.
#
#    This library is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser General Public License for more details.
#
#    You should have received a copy of the GNU Lesser General Public
#    License along with this library; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-->

<!--
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Written by:  Josh Moore, josh at glencoesoftware.com
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-->

<xsl:stylesheet
  xmlns:xsl = "http://www.w3.org/1999/XSL/Transform"
  xmlns:OME="http://www.openmicroscopy.org/Schemas/OME/2008-09"
  xmlns:AML="http://www.openmicroscopy.org/Schemas/AnalysisModule/2008-09"
  xmlns:STD="http://www.openmicroscopy.org/Schemas/STD/2008-09"
  xmlns:Bin="http://www.openmicroscopy.org/Schemas/BinaryFile/2008-09"
  xmlns:CA="http://www.openmicroscopy.org/Schemas/CA/2008-09"
  xmlns:SPW="http://www.openmicroscopy.org/Schemas/SPW/2008-09"
  xmlns:SA="http://www.openmicroscopy.org/Schemas/SA/2008-09"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:xml="http://www.w3.org/XML/1998/namespace"
  xmlns:exsl="http://exslt.org/common"
  extension-element-prefixes="exsl"
  version="1.0">
 <!-- xmlns="http://www.openmicroscopy.org/Schemas/OME/2009-09"-->
  <xsl:variable name="newOMENS">http://www.openmicroscopy.org/Schemas/OME/2009-09</xsl:variable>
  <xsl:variable name="newSPWNS">http://www.openmicroscopy.org/Schemas/SPW/2009-09</xsl:variable>
  <xsl:variable name="newBINNS">http://www.openmicroscopy.org/Schemas/BinaryFile/2009-09</xsl:variable>
  <xsl:variable name="newROINS">http://www.openmicroscopy.org/Schemas/ROI/2009-09</xsl:variable>

  <xsl:output method="xml" indent="yes"/>
  <xsl:preserve-space elements="*"/>
  
  <!-- default value for points attribute for Polygon and PolyLine -->
  <xsl:variable name="pointsDefault" select="'0,0 1,1'"/>
  
  <!-- default value for non-numerical value when transforming the attribute of concrete shape -->
  <xsl:variable name="numberDefault" select="1"/>
  
  <!-- The Enumeration terms to be modified. -->
  <xsl:variable name="enumeration-maps">
    <mapping name="DetectorType">
      <map from="EM-CCD" to="EMCCD"/>
    </mapping>
  </xsl:variable>

 <!-- Transform the value coming from an enumeration -->
 <xsl:template name="transformEnumerationValue">
   <xsl:param name="mappingName"/>
   <xsl:param name="value"/>
   <!-- read the values from the mapping node -->
   <xsl:variable name="mappingNode" select="exsl:node-set($enumeration-maps)/mapping[@name=$mappingName]"/>
   <xsl:variable name="newValue" select="exsl:node-set($mappingNode)/map[@from=$value]/@to"/>
   <xsl:variable name="isOptional" select="exsl:node-set($mappingNode)/@optional"/>
   <xsl:choose>
     <xsl:when test="string-length($newValue) > 0">
       <xsl:value-of select="$newValue"/>
     </xsl:when>
     <xsl:when test="$value = 'Unknown'">
       <xsl:value-of select="'Other'"/>
     </xsl:when>
     <xsl:otherwise>
       <xsl:value-of select="$value"/>
      <!-- If the property is optional we don't want to set 
        "Unknown" if that's our current value. Otherwise use the current value. 
         <xsl:if test="not($isOptional) or $value != 'Unknown'">
        <xsl:value-of select="$value"/>
       </xsl:if>
        
        -->
     <xsl:value-of select="''"/>
     </xsl:otherwise>
   </xsl:choose>
 </xsl:template>

 <!-- Actual schema changes -->

 <!-- data management -->
 <!-- Remove the Locked attribute -->
   <xsl:template match="OME:Dataset">
    <xsl:element name="Dataset" namespace="{$newOMENS}">
      <xsl:copy-of select="@* [not(name() = 'Locked')]"/>  
      <xsl:apply-templates select="node()"/>
    </xsl:element>
  </xsl:template>
  
<!-- 
Convert element into Attribute except GroupRef
Rename attribute OMEName into UserName
-->
 <xsl:template match="OME:Experimenter">
    <xsl:element name="Experimenter" namespace="{$newOMENS}">  
      <xsl:apply-templates select="@*"/>
      <!-- determine the value of the attribute
      Rule: OMEName, Email, LastName+FirstName
      -->
      <xsl:variable name="displayName">
        <xsl:for-each select="* [not(local-name(.) = 'Institution' or local-name(.) = 'GroupRef')]">
            <xsl:choose>
                <xsl:when test="local-name(.) = 'Email'">
                    <!-- check if a OMEName exists. -->
                    <xsl:variable name="omeName">
                        <xsl:copy-of select="following-sibling::OME:OMEName"/>
                    </xsl:variable>                    
                    <xsl:if test="count(exsl:node-set($omeName)/*)=0">
                        <xsl:value-of select="."/>
                    </xsl:if>                    
                </xsl:when>
                <xsl:when test="local-name(.) = 'OMEName'">
                    <xsl:value-of select="."/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="omeName">
                        <xsl:copy-of select="following-sibling::OME:OMEName"/>
                    </xsl:variable>  
                    <xsl:variable name="email">
                        <xsl:copy-of select="following-sibling::OME:Email"/>
                    </xsl:variable>  
                     <xsl:if test="(count(exsl:node-set($omeName)/*)+count(exsl:node-set($email)/*))=0">
                        <xsl:value-of select="."/>
                    </xsl:if>    
                </xsl:otherwise>
             </xsl:choose>
        </xsl:for-each>
     </xsl:variable>

      <!-- insert DisplayName attribute -->
      <xsl:attribute name="DisplayName">
        <xsl:value-of select="$displayName"/>
      </xsl:attribute>
      
      <xsl:for-each select="* [not(local-name(.) = 'GroupRef')]">
          <xsl:choose>
          <xsl:when test="local-name(.) = 'OMEName'">
             <xsl:attribute name="UserName">
              <xsl:value-of select="."/>
            </xsl:attribute>
          </xsl:when>
          <xsl:otherwise>
             <xsl:attribute name="{local-name(.)}">
              <xsl:value-of select="."/>
            </xsl:attribute>
          </xsl:otherwise>
          </xsl:choose>
      </xsl:for-each>
      <xsl:for-each select="* [name() = 'GroupRef']">
        <xsl:element name="{local-name(.)}" namespace="{$newOMENS}">
            <xsl:apply-templates select="@*"/>
            <xsl:value-of select="."/>
        </xsl:element>
      </xsl:for-each>
    </xsl:element>
  </xsl:template>
 
 <!-- Acquisition Settings -->
 
 <!-- Rename ObjectiveRef to ObjectiveSettings -->
  <xsl:template match="OME:ObjectiveRef">
    <xsl:element name="ObjectiveSettings" namespace="{$newOMENS}">
      <xsl:apply-templates select="@*|node()"/>
    </xsl:element>
  </xsl:template>

 <!-- Rename LightSourceRef to LightSettings -->
  <xsl:template match="OME:LightSourceRef">
    <xsl:element name="LightSourceSettings" namespace="{$newOMENS}">
      <xsl:apply-templates select="@*|node()"/>
    </xsl:element>
  </xsl:template>

 <!-- Rename DetectorRef to DetectorSettings -->
  <xsl:template match="OME:DetectorRef">
    <xsl:element name="DetectorSettings" namespace="{$newOMENS}">
      <xsl:apply-templates select="@*|node()"/>
    </xsl:element>
  </xsl:template>


<!-- Instrument components -->

<!--Transform the value of the Transmittance attribute from integer to percentFraction -->
 <xsl:template match="OME:TransmittanceRange">
   <xsl:element name="TransmittanceRange" namespace="{$newOMENS}">
      <xsl:for-each select="@*">
        <xsl:attribute name="{local-name(.)}">
        <xsl:choose>
          <xsl:when test="local-name(.) ='Transmittance'">
            <xsl:call-template name="convertPercentFraction">
              <xsl:with-param name="value"><xsl:value-of select="."/></xsl:with-param>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="."/>
          </xsl:otherwise>
        </xsl:choose>
        </xsl:attribute>
      </xsl:for-each>
    </xsl:element>
 </xsl:template>
 
<!-- Transform the value of RepetitionRate attribute from boolean to float -->
 <xsl:template match="OME:Laser">
   <xsl:variable name="false" select="0"/>
   <xsl:variable name="true" select="1"/>
   <xsl:element name="Laser" namespace="{$newOMENS}">
      <xsl:for-each select="@*">
        <xsl:attribute name="{local-name(.)}">
        <xsl:choose>
          <xsl:when test="local-name(.) ='RepetitionRate'">
            <xsl:choose>
              <xsl:when test="@RepetitionRate = 'true' or @RepetitionRate = 't'">
                <xsl:value-of select="$true"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$false"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:when test="local-name(.) ='Type'">
            <xsl:call-template name="transformEnumerationValue">
                <xsl:with-param name="mappingName" select="'LightSourceType'"/>
                <xsl:with-param name="value"><xsl:value-of select="."/></xsl:with-param>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="."/>
          </xsl:otherwise>
        </xsl:choose>
        </xsl:attribute>
      </xsl:for-each>
      <xsl:apply-templates select="node()"/>
     </xsl:element>
  </xsl:template>

 <!-- Check the value of the Type attribute -->
 <xsl:template match="OME:Arc">
   <xsl:element name="Arc" namespace="{$newOMENS}">
     <xsl:for-each select="@*">
       <xsl:attribute name="{local-name(.)}">
         <xsl:choose>
           <xsl:when test="local-name(.) ='Type'">
             <xsl:call-template name="transformEnumerationValue">
               <xsl:with-param name="mappingName" select="'LightSourceType'"/>
               <xsl:with-param name="value"><xsl:value-of select="."/></xsl:with-param>
             </xsl:call-template>
           </xsl:when>
           <xsl:otherwise>
            <xsl:value-of select="."/>
           </xsl:otherwise>
        </xsl:choose>
       </xsl:attribute>
     </xsl:for-each>
     <xsl:apply-templates select="node()"/>
   </xsl:element>
 </xsl:template>
 
 <!-- Check the value of the Type attribute -->
 <xsl:template match="OME:Filament">
   <xsl:element name="Filament" namespace="{$newOMENS}">
     <xsl:for-each select="@*">
       <xsl:attribute name="{local-name(.)}">
         <xsl:choose>
           <xsl:when test="local-name(.) ='Type'">
             <xsl:call-template name="transformEnumerationValue">
               <xsl:with-param name="mappingName" select="'LightSourceType'"/>
               <xsl:with-param name="value"><xsl:value-of select="."/></xsl:with-param>
             </xsl:call-template>
           </xsl:when>
           <xsl:otherwise>
            <xsl:value-of select="."/>
           </xsl:otherwise>
        </xsl:choose>
       </xsl:attribute>
     </xsl:for-each>
     <xsl:apply-templates select="node()"/>
   </xsl:element>
 </xsl:template>
 
 <!-- Check the value of the Type attribute -->
 <xsl:template match="OME:Microscope">
   <xsl:element name="Microscope" namespace="{$newOMENS}">
     <xsl:for-each select="@*">
       <xsl:attribute name="{local-name(.)}">
         <xsl:choose>
           <xsl:when test="local-name(.) ='Type'">
             <xsl:call-template name="transformEnumerationValue">
               <xsl:with-param name="mappingName" select="'MicroscopeType'"/>
               <xsl:with-param name="value"><xsl:value-of select="."/></xsl:with-param>
             </xsl:call-template>
           </xsl:when>
           <xsl:otherwise>
            <xsl:value-of select="."/>
           </xsl:otherwise>
        </xsl:choose>
       </xsl:attribute>
     </xsl:for-each>
     <xsl:apply-templates select="node()"/>
   </xsl:element>
 </xsl:template>
 
<!-- Rename attributes -->
 <xsl:template match="OME:OTF">
   <xsl:element name="OTF" namespace="{$newOMENS}">
     <xsl:for-each select="@*">
      <xsl:choose>
        <xsl:when test="local-name(.)='PixelType'">
         <xsl:attribute name="Type"><xsl:value-of select="."/></xsl:attribute>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="{local-name(.)}"><xsl:value-of select="."/></xsl:attribute>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
    <xsl:apply-templates select="node()"/>
   </xsl:element>
  </xsl:template>

<!-- Check the value of the type attribute -->
  <xsl:template match="OME:Detector">
    <xsl:element name="Detector" namespace="{$newOMENS}">
      <xsl:for-each select="@*">
        <xsl:attribute name="{local-name(.)}">
          <xsl:choose>
            <xsl:when test="local-name(.)='Type'">
              <xsl:call-template name="transformEnumerationValue">
                <xsl:with-param name="mappingName" select="'DetectorType'"/>
                <xsl:with-param name="value"><xsl:value-of select="."/></xsl:with-param>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="."/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
      </xsl:for-each>
      <xsl:apply-templates select="node()"/>
    </xsl:element>
  
  </xsl:template>
  
<!-- Convert element into Attribute -->
 <xsl:template match="OME:Objective">
    <xsl:element name="Objective" namespace="{$newOMENS}">
      <xsl:for-each select="*">
        <xsl:attribute name="{local-name(.)}">
        <xsl:choose>
          <xsl:when test="local-name(.) ='LensNA'">
            <xsl:call-template name="valueInInterval">
              <xsl:with-param name="value"><xsl:value-of select="."/></xsl:with-param>
              <xsl:with-param name="min" select="0.02"/>
              <xsl:with-param name="max" select="1.5"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:when test="local-name(.)='Correction' or local-name(.)='Immersion'">
              <xsl:call-template name="transformEnumerationValue">
                <xsl:with-param name="mappingName" select="'ObjectiveStuff'"/>
                <xsl:with-param name="value"><xsl:value-of select="."/></xsl:with-param>
              </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="."/>
          </xsl:otherwise>
        </xsl:choose>
        </xsl:attribute>
      </xsl:for-each>
      <xsl:apply-templates select="@*"/>
    </xsl:element>
 </xsl:template>

<!-- 
Convert the attributes EmFilterRef, ExFilterRef and DichroicRef into 
elements EmissionFilterRef, ExcitationFilterRef and DichroicRef.
Copy all the other attributes.
-->  
<xsl:template match="OME:FilterSet">
  <xsl:element name="FilterSet" namespace="{$newOMENS}">
    <xsl:for-each select="@* [not(name() = 'EmFilterRef' or name() = 'ExFilterRef' or name() = 'DichroicRef')]">
      <xsl:attribute name="{local-name(.)}"><xsl:value-of select="."/></xsl:attribute>
    </xsl:for-each>
    <xsl:for-each select="@* [name() = 'EmFilterRef' or name() = 'ExFilterRef' or name() = 'DichroicRef']">
      <xsl:choose>
        <xsl:when test="local-name(.) = 'EmFilterRef'">
          <xsl:element name="EmissionFilterRef">
            <xsl:attribute name="ID"><xsl:value-of select="."/></xsl:attribute>
          </xsl:element>
        </xsl:when>
        <xsl:when test="local-name(.) = 'ExFilterRef'">
          <xsl:element name="ExcitationFilterRef">
            <xsl:attribute name="ID"><xsl:value-of select="."/></xsl:attribute>
          </xsl:element>
        </xsl:when>
        <xsl:otherwise>
          <xsl:element name="{local-name(.)}">
            <xsl:attribute name="ID"><xsl:value-of select="."/></xsl:attribute>
          </xsl:element>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:element>
</xsl:template>

<!-- Image and Pixels -->

<!--
Convert the attibutes of  all the elements except element HashSHA1 into attributes of Plane.
-->
<xsl:template match="OME:Plane">
 <xsl:element name="Plane" namespace="{$newOMENS}">
  <xsl:for-each select="* [not(local-name(.) = 'HashSHA1')]">
    <xsl:for-each select="./@*">
        <xsl:attribute name="{local-name(.)}">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:for-each>
  </xsl:for-each>
  <xsl:apply-templates select="@*"/>
   <xsl:for-each select="* [name() = 'HashSHA1']">
    <xsl:element name="{local-name(.)}" namespace="{$newOMENS}">
        <xsl:apply-templates select="@*"/>
         <xsl:value-of select="."/>
    </xsl:element>
  </xsl:for-each>
 </xsl:element>
</xsl:template>

<!-- 
Rename PixelType attribute to Type 
Remove BigEndian attribute from Pixels and move it to Bin:BinData 
-->   
<xsl:template match="OME:Pixels">
  <xsl:variable name="bg" select="current()/@BigEndian"/>
  <xsl:for-each select="@* [not(local-name(.) ='BigEndian')]">
    <xsl:choose>
      <xsl:when test="local-name(.) = 'PixelType'">
        <xsl:attribute name="Type"><xsl:value-of select="."/></xsl:attribute>
      </xsl:when>
      <xsl:otherwise>
        <xsl:attribute name="{local-name(.)}"><xsl:value-of select="."/></xsl:attribute>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:for-each>
  <xsl:for-each select="*">
    <xsl:call-template name="convertPixelsData">
      <xsl:with-param name="bg" select="$bg"/>
      <xsl:with-param name="node" select="current()"/>
    </xsl:call-template>
  </xsl:for-each>
</xsl:template>

<!-- Rename attribute NumPlanes into PlateCount -->
<xsl:template match="OME:TiffData">
 <xsl:element name="TiffData" namespace="{$newOMENS}">
  <xsl:for-each select="@*">
       <xsl:choose>
         <xsl:when test="local-name(.) = 'NumPlanes'">
          <xsl:attribute name="PlaneCount">
            <xsl:value-of select="."/>
          </xsl:attribute>
         </xsl:when>
         <xsl:otherwise>
          <xsl:attribute name="{local-name(.)}">
            <xsl:value-of select="."/>
          </xsl:attribute>
         </xsl:otherwise>
       </xsl:choose>
    </xsl:for-each>
 </xsl:element>
</xsl:template>

<!-- 
Copy the MicrobeamManipulation node from Image corresponding to the MicrobeamManipulationRef.
-->
<xsl:template match="OME:Experiment">
<xsl:variable name="images">
  <xsl:copy-of select="following-sibling::OME:Image"/>
</xsl:variable>
 <xsl:element name="Experiment" namespace="{$newOMENS}">
 <xsl:apply-templates select="@*"/>
   <xsl:for-each select="*">
    <xsl:choose>
      <xsl:when test="local-name(.) = 'MicrobeamManipulationRef'">
        <xsl:variable name="id" select="@ID"/>
        <xsl:for-each select="exsl:node-set($images)/*">
          <xsl:for-each select="* [name()='MicrobeamManipulation']">
          <xsl:variable name="rois">
            <xsl:copy-of select="preceding-sibling::OME:ROI"/>
          </xsl:variable>
          <xsl:if test="@ID=$id">
            <xsl:element name="{local-name(.)}" namespace="{$newOMENS}">
              <xsl:apply-templates select="@*"/> 
              <xsl:for-each select="*">
                <xsl:choose>
                  <xsl:when test="local-name(.) = 'ROIRef'">
                    <xsl:variable name="roiID" select="@ID"/>
                    <xsl:for-each select="exsl:node-set($rois)/*">
                      <xsl:if test="@ID=$roiID">
                        <xsl:element name="ROI">
                          <xsl:apply-templates select="@*|node()"/>
                        </xsl:element>
                      </xsl:if>
                    </xsl:for-each>     
                  </xsl:when>
                  <xsl:when test="local-name(.) = 'LightSourceRef'">
                    <xsl:apply-templates select="current()"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:element name="{local-name(.)}" namespace="{$newOMENS}">
                      <xsl:apply-templates select="@*|node()"/>
                    </xsl:element>
                  </xsl:otherwise>
                </xsl:choose>
               </xsl:for-each>             
              </xsl:element>
            </xsl:if>
           </xsl:for-each>
         </xsl:for-each>
       </xsl:when>
       <xsl:when test="local-name(.) = 'Description'">
         <xsl:apply-templates select="current()"/>
       </xsl:when>
       <xsl:otherwise>
        <xsl:element name="{local-name(.)}" namespace="{$newOMENS}">
         <xsl:apply-templates select="@*|node()"/>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:for-each>
  </xsl:element>
</xsl:template>

<!--
Remove AcquiredPixels and DefaultPixels attributes.
Remove elements Thumbnail, DisplayOptions, Region and CustomAttributes
MicrobeamManipulation node is moved to Experiment see Experiment template.
LogicalChannel and ChannelComponent are merged: new name is Channel
If a logical channel has n ChannelComponent nodes, n Channel nodes are created.
The Channel nodes are then linked to Pixels and no longer to Image. 
-->
<xsl:template match="OME:Image">
 <xsl:element name="Image" namespace="{$newOMENS}">
    <xsl:variable name="ac" select="current()/@AcquiredPixels"/>
    <xsl:apply-templates select="@* [not(name() = 'DefaultPixels' or name() = 'AcquiredPixels')]"/>
    <xsl:for-each select="* [not(local-name(.) = 'Thumbnail' or local-name(.) = 'DisplayOptions' or local-name(.) = 'Region' or local-name(.) = 'CustomAttributes' or local-name(.) = 'LogicalChannel')]">
        <xsl:choose>
        <xsl:when test="local-name(.) ='Description'">
           <xsl:apply-templates select="current()"/>
         </xsl:when>
         <xsl:when test="local-name(.) = 'CreationDate'">
          <xsl:element name="AcquiredDate" namespace="{$newOMENS}">
            <xsl:value-of select="."/>
          </xsl:element>
         </xsl:when>
         
         <xsl:when test="local-name(.) = 'Pixels'">
            <xsl:if test="@ID=$ac"> <!-- add controls to make sure we only copy one. -->
             <xsl:element name="{local-name(.)}" namespace="{$newOMENS}">
             <xsl:apply-templates select="current()"/>
             <xsl:variable name="pixelsID" select="@ID"/>
             <!-- copy channel to Pixels -->
                <!-- logical channel start -->
                <xsl:variable name="logicalChannels">
                  <xsl:copy-of select="preceding-sibling::OME:LogicalChannel"/>
                </xsl:variable>
                <xsl:for-each select="exsl:node-set($logicalChannels)/*">
                  <xsl:variable name="lc"><xsl:copy-of select="current()"/></xsl:variable>
                  <xsl:for-each select="*  [local-name(.) = 'ChannelComponent']">
                    <xsl:if test="$pixelsID = @Pixels">
                      <xsl:element name="Channel" namespace="{$newOMENS}">
                      <xsl:attribute name="Color">
                        <!-- convert value of @ColorDomain-->
                        <xsl:call-template name="convertColorDomain">
                          <xsl:with-param name="cc" select="@ColorDomain"/>
                        </xsl:call-template>
                      </xsl:attribute>
                      <xsl:for-each select="exsl:node-set($lc)/*">
                        <!-- convert attribute of logicalChannel -->
                        <xsl:for-each select="@* [not(name(.) = 'PhotometricInterpretation')]">
                            <xsl:choose>
                              <xsl:when test="name() = 'Mode'">
                                <xsl:attribute name="AcquisitionMode"><xsl:value-of select="."/></xsl:attribute>
                              </xsl:when>
                              <xsl:when test="name() = 'ExWave'">
                                <xsl:attribute name="ExcitationWavelength"><xsl:value-of select="."/></xsl:attribute>
                              </xsl:when>
                              <xsl:when test="name() = 'EmWave'">
                                <xsl:attribute name="EmissionWavelength"><xsl:value-of select="."/></xsl:attribute>
                              </xsl:when>
                              <xsl:when test="name() = 'NdFilter'">
                                <xsl:attribute name="NDFilter"><xsl:value-of select="."/></xsl:attribute>
                              </xsl:when>
                              <xsl:when test="name() = 'ID'">
                                <xsl:variable name="idLc"><xsl:value-of select="."/></xsl:variable>
                                <xsl:attribute name="{local-name(.)}">
                                  <xsl:call-template name="replace-string-id">
                                    <xsl:with-param name="text" select="$idLc"/>
                                    <xsl:with-param name="replace" select="'LogicalChannel'"/>
                                    <xsl:with-param name="replacement" select="'Channel'"/>
                                  </xsl:call-template> 
                                </xsl:attribute>
                              </xsl:when>
                              <xsl:otherwise>
                                <xsl:attribute name="{local-name(.)}"><xsl:value-of select="."/></xsl:attribute>
                              </xsl:otherwise>
                            </xsl:choose>
                            </xsl:for-each>
                            <xsl:for-each select="* [not(local-name(.) = 'ChannelComponent')]">
                                <xsl:choose>
                                <xsl:when test="local-name(.)='DetectorRef' or local-name(.)='LightSourceRef'">
                                <xsl:apply-templates select="current()"/>
                                </xsl:when>
                                <xsl:otherwise>
                                <xsl:element name="{local-name(.)}" namespace="{$newOMENS}">
                                    <xsl:apply-templates select="@*|node()"/>
                                </xsl:element>
                                </xsl:otherwise>
                                </xsl:choose>
                            </xsl:for-each>
                        </xsl:for-each>
                    </xsl:element>
                    </xsl:if>
                </xsl:for-each>
                </xsl:for-each>
             </xsl:element><!-- logical channel end -->
            </xsl:if>
         </xsl:when>
          <xsl:when test="local-name(.) = 'ObjectiveRef'">
          <xsl:apply-templates select="current()"/>
          </xsl:when>
        <!-- replace MicrobeamManipulation by MicrobeamManipulationRef -->
         <xsl:when test="local-name(.) = 'MicrobeamManipulation'">
            <xsl:variable name="id" select="@ID"/>
            <xsl:element name="MicrobeamManipulationRef" namespace="{$newOMENS}">
              <xsl:attribute name="ID"><xsl:value-of select="$id"/></xsl:attribute>
            </xsl:element>
         </xsl:when>
         <xsl:otherwise>
            <xsl:element name="{local-name(.)}" namespace="{$newOMENS}">
             <xsl:apply-templates select="@*|node()"/>
            </xsl:element>
         </xsl:otherwise>
       </xsl:choose>
    </xsl:for-each>
 </xsl:element>
</xsl:template>

<!-- Transform the LogicalChannel Ref into ChannelRef -->
<xsl:template match="OME:LogicalChannelRef">
 <xsl:element name="ChannelRef" namespace="{$newOMENS}">
 <xsl:for-each select="@*">
   <xsl:choose>
     <xsl:when test="name()='ID'">
     <xsl:variable name="id">
        <xsl:value-of select="current()"/> 
     </xsl:variable>
     <xsl:attribute name="{local-name(.)}">
      <xsl:call-template name="replace-string-id">
        <xsl:with-param name="text" select="$id"/>
        <xsl:with-param name="replace" select="'LogicalChannel'"/>
        <xsl:with-param name="replacement" select="'Channel'"/>
       </xsl:call-template> 
       </xsl:attribute>
     </xsl:when>
     <xsl:otherwise>
     </xsl:otherwise>
   </xsl:choose>
 </xsl:for-each>
</xsl:element>
</xsl:template>

<!-- ROI -->
<!-- Rename all the attributes -->
<xsl:template match="OME:Ellipse">
  <xsl:element name="Ellipse" namespace="{$newROINS}">
  <xsl:for-each select="@*">
    <xsl:variable name="converted">
      <xsl:call-template name="formatNumber">
        <xsl:with-param name="value"><xsl:value-of select="."/></xsl:with-param>
      </xsl:call-template>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="name()='cx'">
        <xsl:attribute name="X"><xsl:value-of select="$converted"/></xsl:attribute>
      </xsl:when>
      <xsl:when test="name()='cy'">
        <xsl:attribute name="Y"><xsl:value-of select="$converted"/></xsl:attribute>
      </xsl:when>
      <xsl:when test="name()='rx'">
        <xsl:attribute name="RadiusX"><xsl:value-of select="$converted"/></xsl:attribute>
      </xsl:when>
      <xsl:when test="name()='ry'">
        <xsl:attribute name="RadiusY"><xsl:value-of select="$converted"/></xsl:attribute>
      </xsl:when>
    </xsl:choose>
  </xsl:for-each>
  </xsl:element>
</xsl:template>

<!-- Rename all the attributes -->
<xsl:template match="OME:Rect">
  <xsl:element name="Rectangle" namespace="{$newROINS}">
  <xsl:for-each select="@* [not(name() ='transform')]">
    <xsl:variable name="converted">
      <xsl:call-template name="formatNumber">
        <xsl:with-param name="value"><xsl:value-of select="."/></xsl:with-param>
      </xsl:call-template>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="name()='x'">
        <xsl:attribute name="X"><xsl:value-of select="$converted"/></xsl:attribute>
      </xsl:when>
      <xsl:when test="name()='y'">
        <xsl:attribute name="Y"><xsl:value-of select="$converted"/></xsl:attribute>
      </xsl:when>
      <xsl:when test="name()='width'">
        <xsl:attribute name="Width"><xsl:value-of select="$converted"/></xsl:attribute>
      </xsl:when>
      <xsl:when test="name()='height'">
        <xsl:attribute name="Height"><xsl:value-of select="$converted"/></xsl:attribute>
      </xsl:when>
    </xsl:choose>
  </xsl:for-each>
  </xsl:element>
</xsl:template>

<!-- Rename attributes cx and cy -->
<xsl:template match="OME:Point">
  <xsl:element name="Point" namespace="{$newROINS}">
  <xsl:for-each select="@* [not(name() ='transform' or name() ='r')]">
    <xsl:variable name="converted">
      <xsl:call-template name="formatNumber">
        <xsl:with-param name="value"><xsl:value-of select="."/></xsl:with-param>
      </xsl:call-template>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="name()='cx'">
        <xsl:attribute name="X"><xsl:value-of select="$converted"/></xsl:attribute>
      </xsl:when>
      <xsl:when test="name()='cy'">
        <xsl:attribute name="Y"><xsl:value-of select="$converted"/></xsl:attribute>
      </xsl:when>
    </xsl:choose>
  </xsl:for-each>
  </xsl:element>
</xsl:template>

<!-- Rename attributes cx and cy -->
<xsl:template match="OME:Line">
  <xsl:element name="Line" namespace="{$newROINS}">
  <xsl:for-each select="@* [not(name() ='transform')]">
    <xsl:variable name="converted">
      <xsl:call-template name="formatNumber">
        <xsl:with-param name="value"><xsl:value-of select="."/></xsl:with-param>
      </xsl:call-template>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="name()='x1'">
        <xsl:attribute name="X1"><xsl:value-of select="$converted"/></xsl:attribute>
      </xsl:when>
      <xsl:when test="name()='x2'">
        <xsl:attribute name="X2"><xsl:value-of select="$converted"/></xsl:attribute>
      </xsl:when>
      <xsl:when test="name()='y1'">
        <xsl:attribute name="Y1"><xsl:value-of select="$converted"/></xsl:attribute>
      </xsl:when>
      <xsl:when test="name()='y2'">
        <xsl:attribute name="Y2"><xsl:value-of select="$converted"/></xsl:attribute>
      </xsl:when>
    </xsl:choose>
  </xsl:for-each>
  </xsl:element>
</xsl:template>

<!-- Rename attributes points -->
<xsl:template match="OME:Polyline">
  <xsl:variable name="default" select="'false'"/>
  <xsl:element name="Polyline" namespace="{$newROINS}">
  <xsl:for-each select="@* [not(name() ='transform')]">
    <xsl:choose>
      <xsl:when test="name()='points'">
        <xsl:attribute name="Points">
          <xsl:call-template name="setPoints">
            <xsl:with-param name="value"><xsl:value-of select="."/></xsl:with-param>
          </xsl:call-template>
        </xsl:attribute>
      </xsl:when>
    </xsl:choose>
  </xsl:for-each>
    <xsl:attribute name="Closed"><xsl:value-of select="$default"/></xsl:attribute>
  </xsl:element>
</xsl:template>

<!-- Rename attributes points -->
<xsl:template match="OME:Polygon">
  <xsl:variable name="default" select="'true'"/>
  <xsl:element name="Polyline" namespace="{$newROINS}">
  <xsl:for-each select="@* [not(name() ='transform')]">
    <xsl:choose>
      <xsl:when test="name()='points'">
        <xsl:attribute name="Points">
          <xsl:call-template name="setPoints">
            <xsl:with-param name="value"><xsl:value-of select="."/></xsl:with-param>
          </xsl:call-template>
        </xsl:attribute>
      </xsl:when>
    </xsl:choose>
  </xsl:for-each>
  <xsl:attribute name="Closed"><xsl:value-of select="$default"/></xsl:attribute>

  </xsl:element>
</xsl:template>

<!-- Sets the value of the points attribute for Polygon and Polyline -->
<xsl:template name="setPoints">
  <xsl:param name="value"/>
  <xsl:choose>
    <xsl:when test="string-length($value) > 0">
      <xsl:value-of select="$value"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$pointsDefault"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- Transform a Circle into an Ellipse -->
<xsl:template match="OME:Circle">
  <xsl:element name="Ellipse" namespace="{$newROINS}">
  <xsl:for-each select="@* [not(name() ='transform')]">
    <xsl:variable name="converted">
      <xsl:call-template name="formatNumber">
        <xsl:with-param name="value"><xsl:value-of select="."/></xsl:with-param>
      </xsl:call-template>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="name()='cx'">
        <xsl:attribute name="X"><xsl:value-of select="$converted"/></xsl:attribute>
      </xsl:when>
      <xsl:when test="name()='cy'">
        <xsl:attribute name="Y"><xsl:value-of select="$converted"/></xsl:attribute>
      </xsl:when>
      <xsl:when test="name()='r'">
        <xsl:attribute name="RadiusX"><xsl:value-of select="$converted"/></xsl:attribute>
        <xsl:attribute name="RadiusY"><xsl:value-of select="$converted"/></xsl:attribute>
      </xsl:when>
    </xsl:choose>
  </xsl:for-each>
  </xsl:element>
</xsl:template>

<!-- Move the ROI to its new name space -->
 <xsl:template match="OME:ROI">
  <xsl:element name="ROI" namespace="{$newROINS}">
    <xsl:apply-templates select="@*|node()"/>
  </xsl:element>
 </xsl:template>
 
<!-- Transform attributes and move the transform attribute from a "real" shape to Shape -->
<xsl:template match="OME:Shape">
  <xsl:element name="Shape" namespace="{$newROINS}">
  <xsl:variable name="shape" select="'Shape:'"/>
  <xsl:variable name="id" select="@ID"/>
  <xsl:variable name="convertedID">
    <xsl:choose>
      <xsl:when test="contains($id, 'Shape')">
        <xsl:value-of select="$id"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$shape"/>
        <xsl:value-of select="$id"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:for-each select="@*">
    <xsl:choose>
      <xsl:when test="name()='theZ'">
        <xsl:attribute name="TheZ"><xsl:value-of select="."/></xsl:attribute>
      </xsl:when>
      <xsl:when test="name()='theT'">
        <xsl:attribute name="TheT"><xsl:value-of select="."/></xsl:attribute>
      </xsl:when>
      <!-- control ID due b/c bug in previous version -->
      <xsl:when test="name()='ID'">
        <xsl:attribute name="{local-name()}">
          <xsl:value-of select="$convertedID"/>
        </xsl:attribute>
      </xsl:when>
      <xsl:otherwise>
       <xsl:attribute name="{local-name()}"><xsl:value-of select="."/></xsl:attribute>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:for-each>
  
  <!-- retrieve the value of the transform attribute -->
  <xsl:variable name="trans">
    <xsl:for-each select="* [not(local-name(.) = 'Channels')]">
      <xsl:value-of select="@transform"/>
    </xsl:for-each>
  </xsl:variable>  
  
  <xsl:attribute name="Transform"><xsl:value-of select="$trans"/></xsl:attribute>
  <xsl:for-each select="*">
     <xsl:choose>
       <xsl:when test="name()='Channels'">
        <xsl:apply-templates select="@*|node()"/>
       </xsl:when>
       <xsl:when test="name()='Mask'">
        <xsl:call-template name="maskTansformation">
          <xsl:with-param name="mask" select="current()"/>
          <xsl:with-param name="id" select="$convertedID"/>
        </xsl:call-template>
        <!-- <xsl:apply-templates select="@*|node()"/>-->
       </xsl:when>
       <xsl:otherwise>
       <xsl:apply-templates select="current()"/>
       </xsl:otherwise>
     </xsl:choose>
  </xsl:for-each>
  </xsl:element>
</xsl:template>
   
<!-- Rename attributes and link to Pixels -->
<xsl:template name="maskTansformation">
  <xsl:param name="mask"/>
  <xsl:param name="id"/>
  <xsl:element name="Mask" namespace="{$newROINS}">
  <xsl:for-each select="$mask/@* [not(name() ='transform' or name() ='width' or name() ='height')]">
    <xsl:choose>
      <xsl:when test="name()='x'">
        <xsl:attribute name="X"><xsl:value-of select="."/></xsl:attribute>
      </xsl:when>
      <xsl:when test="name()='y'">
        <xsl:attribute name="Y"><xsl:value-of select="."/></xsl:attribute>
      </xsl:when>
    </xsl:choose>
  </xsl:for-each>
  <!-- transform MaskPixels -->
  <xsl:variable name="default" select="'1'"/>
  <xsl:variable name="order" select="'XYZCT'"/>
  <xsl:variable name="idText" select="'Pixels:Mask:'"/>
  <xsl:for-each select="exsl:node-set($mask)/*">
    <xsl:choose>
      <xsl:when test="local-name(.)='MaskPixels'">
        <xsl:variable name="bg" select="current()/@BigEndian"/>
        <xsl:element name="Pixels" namespace="{$newOMENS}">
          <xsl:for-each select="@* [not(local-name(.) ='BigEndian')]">
            <xsl:choose>
              <xsl:when test="local-name(.) = 'ExtendedPixelType'">
                <xsl:attribute name="Type"><xsl:value-of select="."/></xsl:attribute>
              </xsl:when>
              <xsl:otherwise>
                <xsl:attribute name="{local-name(.)}"><xsl:value-of select="."/></xsl:attribute>
              </xsl:otherwise>   
             </xsl:choose>
           </xsl:for-each>
           <!-- Add required attribute -->
           <xsl:attribute name="SizeZ"><xsl:value-of select="$default"/></xsl:attribute>
           <xsl:attribute name="SizeT"><xsl:value-of select="$default"/></xsl:attribute>
           <xsl:attribute name="SizeC"><xsl:value-of select="$default"/></xsl:attribute>
           <xsl:attribute name="DimensionOrder"><xsl:value-of select="$order"/></xsl:attribute>
           <xsl:attribute name="ID">
            <xsl:value-of select="$idText"/>
            <xsl:value-of select="$id"/>
           </xsl:attribute>
        <xsl:for-each select="current()/*">
          <xsl:call-template name="convertPixelsData">
            <xsl:with-param name="bg" select="$bg"/>
            <xsl:with-param name="node" select="current()"/>
         </xsl:call-template>
        </xsl:for-each>
      </xsl:element>
      </xsl:when>
      <xsl:otherwise>
         <xsl:apply-templates select="node()"/>
       </xsl:otherwise>
       </xsl:choose>
  </xsl:for-each>
  </xsl:element>
</xsl:template>

<!-- template to transform the possibile data source related to Pixels -->
<xsl:template name="convertPixelsData">
  <xsl:param name="bg"/>
  <xsl:param name="node"/>
  <xsl:choose>
    <xsl:when test="name(.) = 'Bin:BinData'">
      <xsl:element name="{name(.)}" namespace="{$newBINNS}">
        <xsl:attribute name="BigEndian"><xsl:value-of select="$bg"/></xsl:attribute>
        <xsl:apply-templates select="@*|node()"/>
      </xsl:element>
    </xsl:when>
    <xsl:when test="name(.)='Plane' or name(.)='TiffData'">
      <xsl:apply-templates select="current()"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:element name="{local-name(.)}" namespace="{$newOMENS}">
        <xsl:apply-templates select="@*|node()"/>
      </xsl:element>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- Screen Plate Well -->
<!-- 
Remove or rename attributes in WellSample.
Remove Index, Rename PosX to PositionX & PosY to PositionY
-->
<xsl:template match="SPW:WellSample">
  <xsl:element name="WellSample" namespace="{$newSPWNS}">
    <xsl:for-each select="@* [not(name() = 'Index')]">
      <xsl:choose>
        <xsl:when test="name() = 'PosX'">
          <xsl:attribute name="PositionX"><xsl:value-of select="."/></xsl:attribute>
        </xsl:when>
        <xsl:when test="name() = 'PosY'">
          <xsl:attribute name="PositionY"><xsl:value-of select="."/></xsl:attribute>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="{local-name(.)}"><xsl:value-of select="."/></xsl:attribute>
        </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    <xsl:apply-templates select="node()"/>
  </xsl:element>
</xsl:template>
  
<!--  Transform the Row and Column attribute from Integer to nonNegativeInteger -->
 <xsl:template match="SPW:Well">
  <xsl:element name="Well" namespace="{$newSPWNS}">
    <xsl:for-each select="@*">
      <xsl:choose>
        <xsl:when test="name() = 'Row' or name() = 'Column'">
          <xsl:attribute name="{local-name(.)}">
            <xsl:call-template name="isValueValid">
              <xsl:with-param name="value"><xsl:value-of select="."/></xsl:with-param>
              <xsl:with-param name="control" select="0"/>
              <xsl:with-param name="type" select="'less'"/>
            </xsl:call-template>
          </xsl:attribute>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="{local-name(.)}"><xsl:value-of select="."/></xsl:attribute>
        </xsl:otherwise>
        </xsl:choose>
    </xsl:for-each>
    <xsl:apply-templates select="node()"/>
  </xsl:element>
</xsl:template>
 
  <!-- 
  Convert the attribute Description in Plate into a child element.
  Copy all the other attributes.
  Copy all child elements.
  -->
  <xsl:template match="SPW:Plate">
   <xsl:element name="SPW:Plate" namespace="{$newSPWNS}">
      <xsl:for-each select="@* [not(name() = 'Description')]">
        <xsl:attribute name="{local-name(.)}"><xsl:value-of select="."/></xsl:attribute>
      </xsl:for-each>
      <xsl:variable name="des" select="@Description"/>
      <xsl:element name="Description" namespace="{$newSPWNS}">
        <xsl:value-of select="$des"/>
      </xsl:element>
      <xsl:apply-templates select="node()"/>
    </xsl:element>
  </xsl:template>

  <!-- 
  Convert the attribute Description in Plate into a child element.
  Copy all the other attributes.
  Copy all child elements.
  -->
  <xsl:template match="SPW:Reagent">
   <xsl:element name="SPW:Reagent" namespace="{$newSPWNS}">
      <xsl:for-each select="@* [not(name() = 'Description')]">
        <xsl:attribute name="{local-name(.)}"><xsl:value-of select="."/></xsl:attribute>
      </xsl:for-each>
      <xsl:variable name="des" select="@Description"/>
      <xsl:element name="Description" namespace="{$newSPWNS}">
        <xsl:value-of select="$des"/>
      </xsl:element>
      <xsl:apply-templates select="node()"/>
    </xsl:element>
  </xsl:template>
  
<!-- General -->
  <!-- Fix the various Description Elements and Attributes -->
  <!-- 
  Move all Description Elements into same namespace as their 
  parent and strip any lang attributes.
  -->
  <xsl:template match="OME:Description">
    <xsl:choose>
      <xsl:when test="local-name(..) = 'Screen'">
        <xsl:element name="Description" namespace="{$newSPWNS}">
          <xsl:apply-templates select="node()"/>
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:element name="Description" namespace="{$newOMENS}">
          <xsl:apply-templates select="node()"/>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Rewriting all namespaces -->

  <xsl:template match="OME:OME">
<OME xmlns="http://www.openmicroscopy.org/Schemas/OME/2009-09"
    xmlns:CA="http://www.openmicroscopy.org/Schemas/CA/2009-09"
    xmlns:STD="http://www.openmicroscopy.org/Schemas/STD/2009-09"
    xmlns:Bin="http://www.openmicroscopy.org/Schemas/BinaryFile/2009-09"
    xmlns:SPW="http://www.openmicroscopy.org/Schemas/SPW/2009-09"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.openmicroscopy.org/Schemas/OME/2009-09 http://www.openmicroscopy.org/Schemas/OME/2009-09/ome.xsd">
      <xsl:apply-templates/>
   </OME>
  </xsl:template>

  <xsl:template match="OME:*">
    <xsl:element name="{name()}" namespace="http://www.openmicroscopy.org/Schemas/OME/2009-09">
      <xsl:apply-templates select="@*|node()"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="CA:*">
    <xsl:element name="{name()}" namespace="http://www.openmicroscopy.org/Schemas/CA/2009-09">
      <xsl:apply-templates select="@*|node()"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="Bin:*">
    <xsl:element name="{name()}" namespace="http://www.openmicroscopy.org/Schemas/BinaryFile/2009-09">
      <xsl:apply-templates select="@*|node()"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="SA:*">
    <xsl:element name="{name()}" namespace="http://www.openmicroscopy.org/Schemas/SA/2009-09">
      <xsl:apply-templates select="@*|node()"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="SPW:*">
    <xsl:element name="{name()}" namespace="http://www.openmicroscopy.org/Schemas/SPW/2009-09">
      <xsl:apply-templates select="@*|node()"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="STD:*">
    <xsl:element name="{name()}" namespace="http://www.openmicroscopy.org/Schemas/STD/2009-09">
      <xsl:apply-templates select="@*|node()"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="AML:*">
    <xsl:element name="{name()}" namespace="http://www.openmicroscopy.org/Schemas/AML/2009-09">
      <xsl:apply-templates select="@*|node()"/>
    </xsl:element>
  </xsl:template>
  

  <!-- Default processing -->
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="text()|processing-instruction()|comment()">
    <xsl:copy>
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>

<!-- Follow useful list of functions -->
<!--
convert the value of the color domain attribute of ChannelComponent.
A limited number of strings is supported.
-->
<xsl:template name="convertColorDomain">
  <xsl:param name="cc"/>
  <xsl:choose>
    <xsl:when test="contains($cc,'red') or contains($cc,'r')">4278190335</xsl:when>
    <xsl:when test="contains($cc,'green') or contains($cc,'g')">16711935</xsl:when>
    <xsl:when test="contains($cc,'blue') or contains($cc,'b')">65535</xsl:when>
    <xsl:otherwise>4294967295</xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- Replace string -->
<xsl:template name="replace-string-id">
  <xsl:param name="text"/>
  <xsl:param name="replace"/>
  <xsl:param name="replacement"/>
  <xsl:choose>
    <xsl:when test="contains($text, $replace)">
      <xsl:value-of select="substring-before($text, $replace)"/>
      <xsl:value-of select="$replacement"/>
      <xsl:value-of select="substring-after($text, $replace)"/> 
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$text"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- Control if a value is in the specified interval -->
<xsl:template name="valueInInterval">
  <xsl:param name="value"/>
  <xsl:param name="min"/>
  <xsl:param name="max"/>
  <xsl:choose>
    <xsl:when test="$value &lt; $min">
      <xsl:value-of select="$min"/>
    </xsl:when>
    <xsl:when test="$value &gt; $max">
      <xsl:value-of select="$max"/>
    </xsl:when>
    <xsl:otherwise>
     <xsl:value-of select="$value"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!--Convert value to PercentFration -->
<xsl:template name="convertPercentFraction">
  <xsl:param name="value"/>
  <xsl:variable name="min" select="0"/>
  <xsl:variable name="max" select="1"/>
  <xsl:choose>
    <xsl:when test="$value &lt; $min">
      <xsl:value-of select="$min"/>
    </xsl:when>
    <xsl:when test="$value &gt; $max">
      <xsl:call-template name="convertPercentFraction">
        <xsl:with-param name="value">
          <xsl:value-of select="$value div 100"/>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
     <xsl:value-of select="$value"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- 
Controls if a value is greater than or less than depending on the type. 
The types are greater or less.
-->
<xsl:template name="isValueValid">
  <xsl:param name="value"/> 
  <xsl:param name="control"/>
  <xsl:param name="type"/>
  <xsl:choose>
    <xsl:when test="$type = 'less'">
      <xsl:choose>
        <xsl:when test="$value &lt; $control">
          <xsl:value-of select="$control"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$value"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
    <xsl:choose>
        <xsl:when test="$value &gt; $control">
          <xsl:value-of select="$control"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$value"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- Check if the passed value is a number, if not extract number if any -->
<xsl:template name="formatNumber">
  <xsl:param name="value"/>
  <xsl:choose>
    <!-- number already -->
    <xsl:when test="number($value)=number($value)">
      <xsl:value-of select="$value"/>
    </xsl:when>
    <xsl:otherwise><!-- try to find a number -->
      <xsl:value-of select="$numberDefault"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

</xsl:stylesheet>
