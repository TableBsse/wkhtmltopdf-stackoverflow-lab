<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <!-- Mutual infinite recursion: a calls b, b calls a — no depth check in QPatternist -->
  <xsl:template name="a">
    <xsl:call-template name="b"/>
  </xsl:template>

  <xsl:template name="b">
    <xsl:call-template name="a"/>
  </xsl:template>

  <xsl:template match="/">
    <html><body>
      <xsl:call-template name="a"/>
    </body></html>
  </xsl:template>

</xsl:stylesheet>
