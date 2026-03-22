[CmdletBinding()]
param(
  [string]$MarkdownPath = (Join-Path $PSScriptRoot '论文初稿正文.md'),
  [string]$OutputPath = (Join-Path $PSScriptRoot '基于Node+Svelte的私有化共享相册平台_论文初稿.docx')
)

$ErrorActionPreference = 'Stop'

$wdAlignParagraphLeft = 0
$wdAlignParagraphCenter = 1
$wdAlignParagraphRight = 2
$wdAlignParagraphJustify = 3
$wdCollapseEnd = 0
$wdSectionBreakNextPage = 2
$wdPageBreak = 7
$wdFormatXMLDocument = 12
$wdHeaderFooterPrimary = 1
$wdPageNumberAlignCenter = 1
$wdPageNumberStyleArabic = 0
$wdPageNumberStyleUppercaseRoman = 1
$wdLineSpaceSingle = 0
$wdLineSpace1pt5 = 1
$wdBorderBottom = -3
$wdBorderTop = -1
$wdBorderLeft = -2
$wdBorderRight = -4
$wdLineStyleSingle = 1
$wdLineStyleNone = 0
$wdCellAlignVerticalCenter = 1
$wdRowHeightExactly = 2
$wdStatisticPages = 2

$coverInfo = [ordered]@{
  '学    院' = '计算机学院'
  '专    业' = '软件工程'
  '班    级' = '22软件工程7班'
  '学    号' = '202410001661'
  '学生姓名' = '冯健恒'
  '指导教师' = '邓宁宁'
  '提交日期' = (Get-Date -Format 'yyyy 年 M 月 d 日')
}

$abstractCn = @'
随着个人与家庭影像资源数量持续增长，传统以文件夹为核心的管理方式已难以满足用户对照片上传、分类整理、时间线浏览和便捷共享的实际需求。针对这一问题，本文设计并整理了一套基于 Node.js 与 Svelte 的私有化共享相册平台方案。系统采用 B/S 架构，前端基于 Svelte 构建页面与交互逻辑，后端基于 Node.js 与 NestJS 提供业务接口，并结合 PostgreSQL 与 Redis 完成数据存储和运行支撑。根据系统实际页面路由与用户使用流程，平台划分为用户认证与用户中心、照片库、相册、共享协作以及检索与地图五个核心模块。系统能够实现用户登录、资源上传、时间线浏览、收藏归档、相册组织、共享访问、标签分类、地图浏览和地点聚合等主要功能。论文进一步对系统需求分析、总体设计、数据库设计、系统实现与测试过程进行了说明。测试结果表明，该平台能够较好满足私有化共享相册场景下的基本业务需求，具有一定的实用价值和扩展空间。
'@

$abstractEn = @'
With the continuous growth of personal and family photo resources, the traditional folder-based management approach can no longer meet practical needs such as media upload, categorized organization, timeline browsing, and convenient sharing. To address this problem, this paper designs and organizes a private shared photo album platform based on Node.js and Svelte. The system adopts a browser/server architecture. The front end is built with Svelte for page rendering and interaction, while the back end is implemented with Node.js and NestJS to provide business APIs, together with PostgreSQL and Redis for data storage and runtime support. According to the actual route structure and user workflow, the platform is divided into five core modules: user authentication and user center, photo library, albums, sharing and collaboration, and search and map. The system supports major functions including user login, media upload, timeline browsing, favorite and archive management, album organization, shared access, tag-based browsing, map view, and place aggregation. This paper further explains the requirement analysis, overall design, database design, system implementation, and testing process. The test results show that the platform can effectively satisfy the basic business requirements of a private shared photo album system and has practical value and room for further extension.
'@

$keywordsCn = '关键词：私有化相册；共享协作；Node.js；Svelte；Web系统'
$keywordsEn = 'Key Words: private photo album; sharing and collaboration; Node.js; Svelte; web system'

function Convert-MarkdownText {
  param([string]$Text)

  $value = $Text.Trim()
  $value = $value -replace '\[(.*?)\]\((.*?)\)', '$1'
  $value = $value -replace '`', ''
  $value = $value -replace '\*\*', ''
  $value = $value -replace '\*', ''
  $value = $value -replace '^\>\s?', ''
  return $value.Trim()
}

function Set-ParagraphIndent {
  param(
    $ParagraphFormat,
    [double]$IndentCharacters
  )

  try {
    $ParagraphFormat.CharacterUnitFirstLineIndent = $IndentCharacters
  } catch {
    $ParagraphFormat.FirstLineIndent = if ($IndentCharacters -gt 0) { 24 * $IndentCharacters } else { 0 }
  }
}

function Configure-DocumentStyles {
  param($Document)

  $normal = $Document.Styles.Item('正文')
  $normal.Font.NameFarEast = '宋体'
  $normal.Font.NameAscii = 'Times New Roman'
  $normal.Font.NameOther = 'Times New Roman'
  $normal.Font.Size = 12
  $normal.Font.Bold = 0
  $normal.ParagraphFormat.Alignment = $wdAlignParagraphJustify
  $normal.ParagraphFormat.SpaceBefore = 0
  $normal.ParagraphFormat.SpaceAfter = 0
  $normal.ParagraphFormat.LineSpacingRule = $wdLineSpace1pt5
  $normal.ParagraphFormat.LineSpacing = 18
  Set-ParagraphIndent -ParagraphFormat $normal.ParagraphFormat -IndentCharacters 2

  $heading1 = $Document.Styles.Item('标题 1')
  $heading1.Font.NameFarEast = '黑体'
  $heading1.Font.NameAscii = 'Times New Roman'
  $heading1.Font.Size = 16
  $heading1.Font.Bold = 0
  $heading1.ParagraphFormat.Alignment = $wdAlignParagraphCenter
  $heading1.ParagraphFormat.SpaceBefore = 10
  $heading1.ParagraphFormat.SpaceAfter = 10
  $heading1.ParagraphFormat.LineSpacingRule = $wdLineSpace1pt5
  $heading1.ParagraphFormat.LineSpacing = 18
  Set-ParagraphIndent -ParagraphFormat $heading1.ParagraphFormat -IndentCharacters 0

  $heading2 = $Document.Styles.Item('标题 2')
  $heading2.Font.NameFarEast = '黑体'
  $heading2.Font.NameAscii = 'Times New Roman'
  $heading2.Font.Size = 14
  $heading2.Font.Bold = 0
  $heading2.ParagraphFormat.Alignment = $wdAlignParagraphLeft
  $heading2.ParagraphFormat.SpaceBefore = 0
  $heading2.ParagraphFormat.SpaceAfter = 0
  $heading2.ParagraphFormat.LineSpacingRule = $wdLineSpace1pt5
  $heading2.ParagraphFormat.LineSpacing = 18
  Set-ParagraphIndent -ParagraphFormat $heading2.ParagraphFormat -IndentCharacters 0

  $heading3 = $Document.Styles.Item('标题 3')
  $heading3.Font.NameFarEast = '黑体'
  $heading3.Font.NameAscii = 'Times New Roman'
  $heading3.Font.Size = 12
  $heading3.Font.Bold = 0
  $heading3.ParagraphFormat.Alignment = $wdAlignParagraphLeft
  $heading3.ParagraphFormat.SpaceBefore = 0
  $heading3.ParagraphFormat.SpaceAfter = 0
  $heading3.ParagraphFormat.LineSpacingRule = $wdLineSpace1pt5
  $heading3.ParagraphFormat.LineSpacing = 18
  Set-ParagraphIndent -ParagraphFormat $heading3.ParagraphFormat -IndentCharacters 0

  $caption = $Document.Styles.Item('题注')
  $caption.Font.NameFarEast = '宋体'
  $caption.Font.NameAscii = 'Times New Roman'
  $caption.Font.Size = 10.5
  $caption.Font.Bold = 0
  $caption.ParagraphFormat.Alignment = $wdAlignParagraphCenter
  $caption.ParagraphFormat.SpaceBefore = 0
  $caption.ParagraphFormat.SpaceAfter = 0
  $caption.ParagraphFormat.LineSpacingRule = $wdLineSpace1pt5
  $caption.ParagraphFormat.LineSpacing = 18
  Set-ParagraphIndent -ParagraphFormat $caption.ParagraphFormat -IndentCharacters 0
}

function Set-PageSetup {
  param($Section)

  $Section.PageSetup.PageWidth = 595.3
  $Section.PageSetup.PageHeight = 841.9
  $Section.PageSetup.TopMargin = 72
  $Section.PageSetup.BottomMargin = 72
  $Section.PageSetup.LeftMargin = 90
  $Section.PageSetup.RightMargin = 90
  $Section.PageSetup.HeaderDistance = 42.55
  $Section.PageSetup.FooterDistance = 49.6
}

function Reset-SelectionFormat {
  param($Selection)

  $Selection.Font.NameFarEast = '宋体'
  $Selection.Font.NameAscii = 'Times New Roman'
  $Selection.Font.NameOther = 'Times New Roman'
  $Selection.Font.Size = 12
  $Selection.Font.Bold = 0
  $Selection.ParagraphFormat.Alignment = $wdAlignParagraphJustify
  $Selection.ParagraphFormat.SpaceBefore = 0
  $Selection.ParagraphFormat.SpaceAfter = 0
  $Selection.ParagraphFormat.LineSpacingRule = $wdLineSpace1pt5
  $Selection.ParagraphFormat.LineSpacing = 18
  Set-ParagraphIndent -ParagraphFormat $Selection.ParagraphFormat -IndentCharacters 2
}

function Add-StyledParagraph {
  param(
    $Selection,
    [string]$Text,
    [string]$StyleName
  )

  $Selection.Style = $StyleName
  $Selection.TypeText($Text)
  $Selection.TypeParagraph()
}

function Add-CoverLine {
  param(
    $Selection,
    [string]$Text,
    [string]$FontName,
    [double]$Size,
    [bool]$Bold,
    [int]$Alignment = $wdAlignParagraphCenter,
    [double]$SpaceAfter = 0
  )

  $Selection.ParagraphFormat.Alignment = $Alignment
  $Selection.ParagraphFormat.SpaceAfter = $SpaceAfter
  Set-ParagraphIndent -ParagraphFormat $Selection.ParagraphFormat -IndentCharacters 0
  $Selection.Font.NameFarEast = $FontName
  $Selection.Font.NameAscii = 'Times New Roman'
  $Selection.Font.NameOther = 'Times New Roman'
  $Selection.Font.Size = $Size
  $Selection.Font.Bold = if ($Bold) { 1 } else { 0 }
  $Selection.TypeText($Text)
  $Selection.TypeParagraph()
}

function Add-BlankParagraphs {
  param(
    $Selection,
    [int]$Count
  )

  for ($i = 0; $i -lt $Count; $i++) {
    $Selection.TypeParagraph()
  }
}

function Format-TableCell {
  param(
    $Cell,
    [string]$Text,
    [string]$FontName = '宋体',
    [double]$Size = 12,
    [bool]$Bold = $false,
    [int]$Alignment = $wdAlignParagraphLeft
  )

  $range = $Cell.Range
  $range.Text = $Text
  $range.Font.NameFarEast = $FontName
  $range.Font.NameAscii = 'Times New Roman'
  $range.Font.NameOther = 'Times New Roman'
  $range.Font.Size = $Size
  $range.Font.Bold = if ($Bold) { 1 } else { 0 }
  $range.ParagraphFormat.Alignment = $Alignment
  $range.ParagraphFormat.SpaceBefore = 0
  $range.ParagraphFormat.SpaceAfter = 0
  $range.ParagraphFormat.LineSpacingRule = $wdLineSpace1pt5
  $range.ParagraphFormat.LineSpacing = 18
  Set-ParagraphIndent -ParagraphFormat $range.ParagraphFormat -IndentCharacters 0
  $Cell.VerticalAlignment = $wdCellAlignVerticalCenter
}

function Add-CoverPage {
  param(
    $Document,
    $Selection
  )

  Add-BlankParagraphs -Selection $Selection -Count 2
  Add-CoverLine -Selection $Selection -Text '广州应用科技学院' -FontName '黑体' -Size 22 -Bold $true -SpaceAfter 18
  Add-CoverLine -Selection $Selection -Text '本科毕业设计（论文）' -FontName '黑体' -Size 20 -Bold $true -SpaceAfter 42
  Add-CoverLine -Selection $Selection -Text '基于Node+Svelte的私有化共享相册平台' -FontName '黑体' -Size 18 -Bold $true -SpaceAfter 18
  Add-BlankParagraphs -Selection $Selection -Count 5

  $table = $Document.Tables.Add($Selection.Range, $coverInfo.Count, 2)
  $table.Borders.Enable = 0
  $table.Rows.Alignment = $wdAlignParagraphCenter
  $table.Columns.Item(1).Width = 120
  $table.Columns.Item(2).Width = 240

  $rowIndex = 1
  foreach ($item in $coverInfo.GetEnumerator()) {
    Format-TableCell -Cell $table.Cell($rowIndex, 1) -Text $item.Key -FontName '宋体' -Size 14 -Bold $false -Alignment $wdAlignParagraphLeft
    Format-TableCell -Cell $table.Cell($rowIndex, 2) -Text $item.Value -FontName '宋体' -Size 14 -Bold $false -Alignment $wdAlignParagraphLeft
    $table.Cell($rowIndex, 2).Borders.Item($wdBorderBottom).LineStyle = $wdLineStyleSingle
    $table.Cell($rowIndex, 2).Borders.Item($wdBorderBottom).LineWidth = 6
    $table.Cell($rowIndex, 2).Borders.Item($wdBorderTop).LineStyle = $wdLineStyleNone
    $table.Cell($rowIndex, 2).Borders.Item($wdBorderLeft).LineStyle = $wdLineStyleNone
    $table.Cell($rowIndex, 2).Borders.Item($wdBorderRight).LineStyle = $wdLineStyleNone
    $rowIndex++
  }

  $Selection.SetRange($table.Range.End, $table.Range.End)
  Add-BlankParagraphs -Selection $Selection -Count 2
}

function Add-ChapterHeading {
  param(
    $Selection,
    [int]$Level,
    [string]$Text,
    [bool]$ForcePageBreak = $false
  )

  if ($ForcePageBreak) {
    $Selection.InsertBreak($wdPageBreak)
  }

  switch ($Level) {
    1 { Add-StyledParagraph -Selection $Selection -Text $Text -StyleName '标题 1' }
    2 { Add-StyledParagraph -Selection $Selection -Text $Text -StyleName '标题 2' }
    3 { Add-StyledParagraph -Selection $Selection -Text $Text -StyleName '标题 3' }
  }
}

function Add-BodyParagraph {
  param(
    $Selection,
    [string]$Text
  )

  $value = Convert-MarkdownText -Text $Text
  if ([string]::IsNullOrWhiteSpace($value)) {
    return
  }

  Add-StyledParagraph -Selection $Selection -Text $value -StyleName '正文'
}

function Add-CaptionParagraph {
  param(
    $Selection,
    [string]$Text
  )

  Add-StyledParagraph -Selection $Selection -Text $Text -StyleName '题注'
}

function Add-FigurePlaceholder {
  param(
    $Document,
    $Selection,
    [string]$Caption
  )

  Reset-SelectionFormat -Selection $Selection
  $figureTable = $Document.Tables.Add($Selection.Range, 1, 1)
  $figureTable.Borders.Enable = 1
  $figureTable.Rows.HeightRule = $wdRowHeightExactly
  $figureTable.Rows.Height = 170
  $figureTable.Columns.Item(1).Width = 360
  $figureTable.Cell(1, 1).Range.Text = "图片占位`r请在此处插入$Caption"
  $figureTable.Cell(1, 1).Range.Font.NameFarEast = '宋体'
  $figureTable.Cell(1, 1).Range.Font.NameAscii = 'Times New Roman'
  $figureTable.Cell(1, 1).Range.Font.Size = 12
  $figureTable.Cell(1, 1).Range.ParagraphFormat.Alignment = $wdAlignParagraphCenter
  $figureTable.Cell(1, 1).VerticalAlignment = $wdCellAlignVerticalCenter
  $Selection.SetRange($figureTable.Range.End, $figureTable.Range.End)
  $Selection.TypeParagraph()
  Add-CaptionParagraph -Selection $Selection -Text $Caption
}

function Add-TablePlaceholder {
  param(
    $Document,
    $Selection,
    [string]$Caption
  )

  Add-CaptionParagraph -Selection $Selection -Text $Caption
  Reset-SelectionFormat -Selection $Selection
  $table = $Document.Tables.Add($Selection.Range, 4, 4)
  $table.Borders.Enable = 1
  $table.Rows.Alignment = $wdAlignParagraphCenter
  for ($c = 1; $c -le 4; $c++) {
    Format-TableCell -Cell $table.Cell(1, $c) -Text ("列{0}" -f $c) -FontName '宋体' -Size 10.5 -Bold $true -Alignment $wdAlignParagraphCenter
  }
  $table.Cell(2, 1).Merge($table.Cell(2, 4))
  Format-TableCell -Cell $table.Cell(2, 1) -Text '表格内容占位，后续替换为实际测试表或设计表' -FontName '宋体' -Size 10.5 -Bold $false -Alignment $wdAlignParagraphCenter
  for ($r = 3; $r -le 4; $r++) {
    for ($c = 1; $c -le 4; $c++) {
      Format-TableCell -Cell $table.Cell($r, $c) -Text '' -FontName '宋体' -Size 10.5 -Bold $false -Alignment $wdAlignParagraphCenter
    }
  }
  $Selection.SetRange($table.Range.End, $table.Range.End)
  $Selection.TypeParagraph()
}

function Add-FrontMatter {
  param(
    $Document,
    $Selection
  )

  Add-ChapterHeading -Selection $Selection -Level 1 -Text '摘要'
  Add-BodyParagraph -Selection $Selection -Text $abstractCn
  Add-BodyParagraph -Selection $Selection -Text $keywordsCn

  $Selection.InsertBreak($wdPageBreak)
  Add-ChapterHeading -Selection $Selection -Level 1 -Text 'Abstract'
  Add-BodyParagraph -Selection $Selection -Text $abstractEn
  Add-BodyParagraph -Selection $Selection -Text $keywordsEn

  $Selection.InsertBreak($wdPageBreak)
  Add-CoverLine -Selection $Selection -Text '目 录' -FontName '黑体' -Size 16 -Bold $true -SpaceAfter 12
  Reset-SelectionFormat -Selection $Selection
  $toc = $Document.TablesOfContents.Add($Selection.Range, $true, 1, 3)
  $Selection.SetRange($toc.Range.End, $toc.Range.End)
}

function Add-MainBodyFromMarkdown {
  param(
    $Document,
    $Selection,
    [string]$Path
  )

  $raw = Get-Content -Raw -Encoding utf8 $Path
  $normalized = $raw -replace "`r`n", "`n"
  $blocks = $normalized -split "`n`n+"
  $chapterCount = 0

  foreach ($block in $blocks) {
    $text = $block.Trim()
    if ([string]::IsNullOrWhiteSpace($text)) {
      continue
    }

    if ($text -match '^#\s+') {
      continue
    }

    if ($text -match '^##\s+(.+)$') {
      $chapterCount++
      Add-ChapterHeading -Selection $Selection -Level 1 -Text (Convert-MarkdownText -Text $matches[1]) -ForcePageBreak ($chapterCount -gt 1)
      continue
    }

    if ($text -match '^###\s+(.+)$') {
      Add-ChapterHeading -Selection $Selection -Level 2 -Text (Convert-MarkdownText -Text $matches[1])
      continue
    }

    if ($text -match '^####\s+(.+)$') {
      Add-ChapterHeading -Selection $Selection -Level 3 -Text (Convert-MarkdownText -Text $matches[1])
      continue
    }

    if ($text -match '^\[此处插入(图[^\]]+)\]$') {
      Add-FigurePlaceholder -Document $Document -Selection $Selection -Caption (Convert-MarkdownText -Text $matches[1])
      continue
    }

    if ($text -match '^\[此处插入(表[^\]]+)\]$') {
      Add-TablePlaceholder -Document $Document -Selection $Selection -Caption (Convert-MarkdownText -Text $matches[1])
      continue
    }

    Add-BodyParagraph -Selection $Selection -Text $text
  }
}

function Add-EndingSections {
  param(
    $Selection
  )

  Add-ChapterHeading -Selection $Selection -Level 1 -Text '参考文献' -ForcePageBreak $true
  Add-BodyParagraph -Selection $Selection -Text '参考文献内容由作者后续按学校规范补充。'

  Add-ChapterHeading -Selection $Selection -Level 1 -Text '致谢' -ForcePageBreak $true
  Add-BodyParagraph -Selection $Selection -Text '在本次毕业设计与论文撰写过程中，感谢指导教师在选题、写作和修改过程中的耐心指导，感谢学院老师和同学在学习与实践过程中给予的帮助与支持。'
}

function Configure-SectionPageNumbers {
  param(
    $Section,
    [int]$NumberStyle,
    [bool]$Restart,
    [int]$StartAt
  )

  $footer = $Section.Footers.Item($wdHeaderFooterPrimary)
  $footer.LinkToPrevious = $false
  if ($footer.PageNumbers.Count -gt 0) {
    $footer.PageNumbers.NumberStyle = $NumberStyle
    $footer.PageNumbers.RestartNumberingAtSection = $Restart
    $footer.PageNumbers.StartingNumber = $StartAt
  } else {
    $footer.PageNumbers.Add($wdPageNumberAlignCenter, $true) | Out-Null
    $footer.PageNumbers.NumberStyle = $NumberStyle
    $footer.PageNumbers.RestartNumberingAtSection = $Restart
    $footer.PageNumbers.StartingNumber = $StartAt
  }
}

if (-not (Test-Path -LiteralPath $MarkdownPath)) {
  throw "Markdown 文件不存在：$MarkdownPath"
}

$outputDirectory = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outputDirectory)) {
  New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
}

$word = $null
$document = $null

try {
  $word = New-Object -ComObject Word.Application
  $word.Visible = $false
  $word.DisplayAlerts = 0

  $document = $word.Documents.Add()
  Configure-DocumentStyles -Document $document
  Set-PageSetup -Section $document.Sections.Item(1)

  $selection = $word.Selection
  Reset-SelectionFormat -Selection $selection

  Add-CoverPage -Document $document -Selection $selection

  $selection.InsertBreak($wdSectionBreakNextPage)
  Set-PageSetup -Section $document.Sections.Item(2)
  Configure-SectionPageNumbers -Section $document.Sections.Item(2) -NumberStyle $wdPageNumberStyleUppercaseRoman -Restart $true -StartAt 1

  Add-FrontMatter -Document $document -Selection $selection

  $selection.InsertBreak($wdSectionBreakNextPage)
  Set-PageSetup -Section $document.Sections.Item(3)
  Configure-SectionPageNumbers -Section $document.Sections.Item(3) -NumberStyle $wdPageNumberStyleArabic -Restart $true -StartAt 1

  Add-MainBodyFromMarkdown -Document $document -Selection $selection -Path $MarkdownPath
  Add-EndingSections -Selection $selection

  if ($document.TablesOfContents.Count -gt 0) {
    $document.TablesOfContents.Item(1).Update()
    $document.TablesOfContents.Item(1).UpdatePageNumbers()
  }

  $document.Fields.Update() | Out-Null
  $document.SaveAs([ref]$OutputPath, [ref]$wdFormatXMLDocument)
  $document.Close()
  $document = $null
  $word.Quit()
  $word = $null

  Write-Output "DOCX_CREATED: $OutputPath"
} finally {
  if ($document -ne $null) {
    $document.Close([ref]$false)
  }

  if ($word -ne $null) {
    $word.Quit()
  }
}


