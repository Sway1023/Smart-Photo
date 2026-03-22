[CmdletBinding()]
param(
  [string]$MarkdownPath,
  [string]$OutputPath,
  [switch]$Landscape
)

$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($MarkdownPath)) {
  $MarkdownPath = Join-Path $scriptRoot '第二章_系统需求分析.md'
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
  $OutputPath = Join-Path $scriptRoot '第二章_系统需求分析.docx'
}

$ErrorActionPreference = 'Stop'

$wdAlignParagraphLeft = 0
$wdAlignParagraphCenter = 1
$wdAlignParagraphRight = 2
$wdAlignParagraphJustify = 3
$wdCollapseEnd = 0
$wdPageBreak = 7
$wdFormatXMLDocument = 12
$wdFormatDocument97 = 0
$wdHeaderFooterPrimary = 1
$wdPageNumberAlignCenter = 1
$wdPageNumberStyleArabic = 0
$wdLineSpace1pt5 = 1
$wdBorderBottom = -3
$wdCellAlignVerticalCenter = 1
$wdVerticalPositionRelativeToPage = 6
$wdOrientPortrait = 0
$wdOrientLandscape = 1
$wdAutoFitWindow = 2
$msoFalse = 0
$msoTrue = -1
$msoShapeRectangle = 1
$msoShapeDiamond = 4
$msoShapeRoundedRectangle = 5
$msoShapeOval = 9

$tableSpecs = [ordered]@{
  'LOGIN' = [ordered]@{
    Number = '2-1'
    Name = '登录系统'
    Description = '注册用户在登录页面输入账号与密码，经系统校验后进入平台主页。'
    Actor = '注册用户'
    Precondition = '用户已完成账户注册，系统服务处于可用状态。'
    Postcondition = '系统建立有效会话，用户进入主业务页面。'
    Stakeholders = '注册用户希望快速、安全地进入系统。'
    BasicPath = @(
      '1. 用户打开登录页面。'
      '2. 用户输入账号与密码并提交。'
      '3. 系统校验身份信息。'
      '4. 系统创建会话并跳转至主页面。'
    )
    ExtensionPath = @(
      '1a. 用户输入信息不完整，系统提示补全。'
      '3a. 账号或密码错误，系统提示重新输入。'
    )
    Fields = '账号、密码、登录状态、会话标识。'
    Rules = '未通过认证的用户不得进入业务页面；登录成功后应维护当前会话状态。'
    Remark = '该用例是其他注册用户业务的前置入口。'
  }
  'ADMIN_USER' = [ordered]@{
    Number = '2-2'
    Name = '管理用户信息'
    Description = '管理员对平台用户执行查看、编辑和状态维护等管理操作。'
    Actor = '管理员'
    Precondition = '管理员已登录系统并具备后台管理权限。'
    Postcondition = '用户信息或用户状态被更新，管理列表同步刷新。'
    Stakeholders = '管理员希望平台用户信息准确、权限状态清晰。'
    BasicPath = @(
      '1. 管理员进入用户管理页面。'
      '2. 系统加载用户列表。'
      '3. 管理员选择目标用户并编辑信息或状态。'
      '4. 系统保存更新结果并刷新列表。'
    )
    ExtensionPath = @(
      '2a. 用户列表加载失败，系统提示稍后重试。'
      '3a. 提交参数不合法，系统提示修正。'
    )
    Fields = '用户名称、邮箱、角色、启用状态、头像等。'
    Rules = '管理员功能与普通用户功能分离；用户状态变更后应即时生效。'
    Remark = '该用例对应管理员角色的核心后台功能。'
  }
  'ASSET' = [ordered]@{
    Number = '2-3'
    Name = '上传与管理资源'
    Description = '注册用户上传照片资源，并对资源执行查看、收藏、归档、锁定、删除与恢复等操作。'
    Actor = '注册用户'
    Precondition = '用户已登录系统，且拥有可用的上传资源。'
    Postcondition = '资源数据与状态被更新，页面展示结果同步变化。'
    Stakeholders = '注册用户希望高效完成照片保存、整理和维护。'
    BasicPath = @(
      '1. 用户进入照片库页面。'
      '2. 用户选择本地照片并提交上传。'
      '3. 系统保存资源记录、文件信息与元数据。'
      '4. 系统刷新照片列表并展示新资源。'
      '5. 用户对资源执行收藏、归档、锁定或删除等操作。'
      '6. 系统更新资源状态并同步相关页面。'
    )
    ExtensionPath = @(
      '2a. 上传文件不符合要求，系统拒绝保存。'
      '3a. 上传过程中发生异常，系统提示上传失败。'
      '6a. 资源恢复后，系统重新在主照片库中显示资源。'
    )
    Fields = '资源文件、拍摄时间、收藏状态、归档状态、锁定状态、删除状态。'
    Rules = '用户仅能管理自身权限范围内的资源；资源状态变更应保持页面一致性。'
    Remark = '该用例覆盖照片库模块最核心的业务流程。'
  }
  'ALBUM' = [ordered]@{
    Number = '2-4'
    Name = '管理相册'
    Description = '注册用户创建相册并维护相册中的资源和成员信息。'
    Actor = '注册用户'
    Precondition = '用户已登录系统，且系统中已有可入册资源。'
    Postcondition = '相册信息、资源关联或成员关系发生更新。'
    Stakeholders = '注册用户希望按主题组织照片并支持协作访问。'
    BasicPath = @(
      '1. 用户进入相册页面。'
      '2. 用户创建新相册并填写基础信息。'
      '3. 系统保存相册并展示在相册列表中。'
      '4. 用户向相册中加入或移除资源。'
      '5. 用户维护相册成员与访问权限。'
    )
    ExtensionPath = @(
      '2a. 相册名称为空，系统提示补充。'
      '4a. 资源重复入册时，系统保持关联唯一性。'
    )
    Fields = '相册名称、描述、封面资源、成员信息、资源关联。'
    Rules = '相册与资源的关联关系应保持一致；成员权限变更后应立即影响访问范围。'
    Remark = '该用例反映平台的主题化资源组织能力。'
  }
  'SHARED_LINK' = [ordered]@{
    Number = '2-5'
    Name = '创建共享链接'
    Description = '注册用户针对指定资源或相册生成共享链接，并设置访问控制参数。'
    Actor = '注册用户'
    Precondition = '用户已登录系统，且选中了可共享的资源或相册。'
    Postcondition = '系统生成可访问的共享链接，并保存共享规则。'
    Stakeholders = '注册用户希望快速将照片分发给他人，同时控制访问范围。'
    BasicPath = @(
      '1. 用户进入共享页面。'
      '2. 用户选择共享对象并设置密码、有效期等参数。'
      '3. 系统保存共享配置并生成共享链接。'
      '4. 用户复制链接并发送给目标访问者。'
    )
    ExtensionPath = @(
      '2a. 用户未选择共享对象，系统提示先选择资源。'
      '3a. 共享保存失败，系统提示重新提交。'
    )
    Fields = '共享对象、共享密码、有效期、链接标识、创建时间。'
    Rules = '共享链接生成后应唯一可识别；访问控制参数应在访问阶段被校验。'
    Remark = '该用例是共享协作模块的重要入口。'
  }
  'SHARED_ACCESS' = [ordered]@{
    Number = '2-6'
    Name = '访问共享资源'
    Description = '共享访问者通过链接访问被授权资源，并在符合条件时查看或下载内容。'
    Actor = '共享访问者'
    Precondition = '访问者已获得有效共享链接。'
    Postcondition = '访问者成功查看共享资源，或因条件不满足而被拒绝访问。'
    Stakeholders = '共享访问者希望在受控条件下便捷访问照片资源。'
    BasicPath = @(
      '1. 访问者打开共享链接。'
      '2. 系统校验链接状态、密码和有效期。'
      '3. 校验通过后，系统展示共享资源页面。'
      '4. 访问者浏览或下载被授权内容。'
    )
    ExtensionPath = @(
      '2a. 共享链接已过期，系统提示链接失效。'
      '2b. 密码输入错误，系统提示重新输入。'
    )
    Fields = '共享标识、访问密码、有效期、访问状态、资源列表。'
    Rules = '只有满足访问条件的请求才允许进入共享页面；失效链接不得继续访问。'
    Remark = '该用例对应系统的外部访问场景。'
  }
  'SEARCH' = [ordered]@{
    Number = '2-7'
    Name = '检索与定位资源'
    Description = '注册用户通过搜索、标签、地图和地点聚合等方式快速定位目标资源。'
    Actor = '注册用户'
    Precondition = '用户已登录系统，系统中存在可检索资源。'
    Postcondition = '系统返回符合条件的资源结果，并支持进一步查看。'
    Stakeholders = '注册用户希望在大量照片中快速找到目标内容。'
    BasicPath = @(
      '1. 用户进入搜索、标签、地图或地点页面。'
      '2. 用户输入条件或选择筛选维度。'
      '3. 系统根据元数据、标签或位置信息返回结果。'
      '4. 用户查看目标资源详情。'
    )
    ExtensionPath = @(
      '2a. 检索条件为空时，系统按默认方式展示结果。'
      '3a. 无匹配资源时，系统显示空结果提示。'
    )
    Fields = '检索条件、标签名称、地点信息、地图标记、结果列表。'
    Rules = '检索结果应受当前用户权限约束；地图与地点展示应与资源位置信息一致。'
    Remark = '该用例体现系统的分类浏览与定位能力。'
  }
}

function Convert-MarkdownText {
  param([string]$Text)

  $value = $Text.Trim()
  $value = $value -replace '\[(.*?)\]\((.*?)\)', '$1'
  $value = $value -replace '`', ''
  $value = $value -replace '\*\*', ''
  $value = $value -replace '\*', ''
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
  $heading1.Font.NameOther = 'Times New Roman'
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
  $heading2.Font.NameOther = 'Times New Roman'
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
  $heading3.Font.NameOther = 'Times New Roman'
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
  $caption.Font.NameOther = 'Times New Roman'
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
  param(
    $Section,
    [bool]$Landscape = $false
  )

  $Section.PageSetup.Orientation = if ($Landscape) { $wdOrientLandscape } else { $wdOrientPortrait }
  if ($Landscape) {
    $Section.PageSetup.PageWidth = 841.9
    $Section.PageSetup.PageHeight = 595.3
  } else {
    $Section.PageSetup.PageWidth = 595.3
    $Section.PageSetup.PageHeight = 841.9
  }
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

function Add-Heading {
  param(
    $Selection,
    [int]$Level,
    [string]$Text
  )

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

  Reset-SelectionFormat -Selection $Selection
  $Selection.Style = '正文'

  if ($value -match '^\d+\.\s') {
    Set-ParagraphIndent -ParagraphFormat $Selection.ParagraphFormat -IndentCharacters 0
  } elseif ($value -match '^（\d+）') {
    Set-ParagraphIndent -ParagraphFormat $Selection.ParagraphFormat -IndentCharacters 0
  } elseif ($value -match '^[①②③④⑤⑥⑦⑧⑨⑩]') {
    $Selection.ParagraphFormat.CharacterUnitLeftIndent = 2
    Set-ParagraphIndent -ParagraphFormat $Selection.ParagraphFormat -IndentCharacters 0
  } else {
    $Selection.ParagraphFormat.CharacterUnitLeftIndent = 0
    Set-ParagraphIndent -ParagraphFormat $Selection.ParagraphFormat -IndentCharacters 2
  }

  $Selection.TypeText($value)
  $Selection.TypeParagraph()
}

function Add-CaptionParagraph {
  param(
    $Selection,
    [string]$Text
  )

  Add-StyledParagraph -Selection $Selection -Text $Text -StyleName '题注'
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

function Set-PageNumbers {
  param($Document)

  $footer = $Document.Sections.Item(1).Footers.Item($wdHeaderFooterPrimary)
  $footer.PageNumbers.RestartNumberingAtSection = $msoFalse
  $footer.PageNumbers.Add($wdPageNumberAlignCenter, $msoTrue) | Out-Null
  $footer.PageNumbers.NumberStyle = $wdPageNumberStyleArabic
}

function Format-ShapeText {
  param(
    $Shape,
    [string]$Text,
    [double]$Size = 10.5,
    [bool]$Bold = $false,
    [int]$Alignment = $wdAlignParagraphCenter
  )

  $Shape.Fill.Visible = $msoFalse
  $Shape.Line.Visible = $msoTrue
  $Shape.Line.ForeColor.RGB = 0
  $Shape.TextFrame.MarginLeft = 4
  $Shape.TextFrame.MarginRight = 4
  $Shape.TextFrame.MarginTop = 2
  $Shape.TextFrame.MarginBottom = 2
  $Shape.TextFrame.TextRange.Text = $Text
  $Shape.TextFrame.TextRange.Font.NameFarEast = '宋体'
  $Shape.TextFrame.TextRange.Font.NameAscii = 'Times New Roman'
  $Shape.TextFrame.TextRange.Font.Size = $Size
  $Shape.TextFrame.TextRange.Font.Bold = if ($Bold) { 1 } else { 0 }
  $Shape.TextFrame.TextRange.ParagraphFormat.Alignment = $Alignment
}

function Add-DiagramCanvas {
  param(
    $Document,
    $Selection,
    [double]$Width,
    [double]$Height
  )

  $currentTop = [double]$Selection.Information($wdVerticalPositionRelativeToPage)
  if ($currentTop -lt 0) {
    $currentTop = 100
  }

  if (($currentTop + $Height + 70) -gt 700) {
    $Selection.InsertBreak($wdPageBreak)
    Reset-SelectionFormat -Selection $Selection
    $currentTop = 90
  }

  $anchor = $Selection.Range.Duplicate
  $anchor.Collapse($wdCollapseEnd)
  $canvas = $Document.Shapes.AddCanvas(80, ($currentTop + 5), $Width, $Height, $anchor)
  return $canvas
}

function Reset-SelectionToShapeAnchor {
  param(
    $Selection,
    $Shape
  )

  $range = $Shape.Anchor.Duplicate
  $range.Collapse($wdCollapseEnd)
  $Selection.SetRange($range.End, $range.End)
  Reset-SelectionFormat -Selection $Selection
}

function New-DiagramContext {
  param(
    $Document,
    $Selection,
    [double]$Width,
    [double]$Height
  )

  $currentTop = [double]$Selection.Information($wdVerticalPositionRelativeToPage)
  if ($currentTop -lt 0) {
    $currentTop = 100
  }

  if (($currentTop + $Height + 70) -gt 700) {
    $Selection.InsertBreak($wdPageBreak)
    Reset-SelectionFormat -Selection $Selection
    $currentTop = 90
  }

  $anchor = $Selection.Range.Duplicate
  $anchor.Collapse($wdCollapseEnd)

  return [pscustomobject]@{
    Document = $Document
    Anchor = $anchor
    BaseLeft = 80
    BaseTop = $currentTop + 5
  }
}

function Reset-SelectionToDiagramAnchor {
  param(
    $Selection,
    $Diagram
  )

  $Selection.SetRange($Diagram.Anchor.End, $Diagram.Anchor.End)
  Reset-SelectionFormat -Selection $Selection
}

function Add-DiagramBox {
  param(
    $Diagram,
    [int]$Type,
    [double]$Left,
    [double]$Top,
    [double]$Width,
    [double]$Height,
    [string]$Text,
    [double]$Size = 10.5,
    [bool]$Bold = $false
  )

  $shape = $Diagram.Document.Shapes.AddShape(
    $Type,
    $Diagram.BaseLeft + $Left,
    $Diagram.BaseTop + $Top,
    $Width,
    $Height,
    $Diagram.Anchor
  )
  Format-ShapeText -Shape $shape -Text $Text -Size $Size -Bold $Bold
  return $shape
}

function Add-DiagramLine {
  param(
    $Diagram,
    [double]$X1,
    [double]$Y1,
    [double]$X2,
    [double]$Y2
  )

  $line = $Diagram.Document.Shapes.AddLine(
    $Diagram.BaseLeft + $X1,
    $Diagram.BaseTop + $Y1,
    $Diagram.BaseLeft + $X2,
    $Diagram.BaseTop + $Y2,
    $Diagram.Anchor
  )
  $line.Line.ForeColor.RGB = 0
  return $line
}

function Add-DiagramText {
  param(
    $Diagram,
    [double]$Left,
    [double]$Top,
    [double]$Width,
    [double]$Height,
    [string]$Text,
    [double]$Size = 9.5
  )

  $shape = $Diagram.Document.Shapes.AddTextBox(
    1,
    $Diagram.BaseLeft + $Left,
    $Diagram.BaseTop + $Top,
    $Width,
    $Height,
    $Diagram.Anchor
  )
  $shape.Line.Visible = $msoFalse
  $shape.Fill.Visible = $msoFalse
  Format-ShapeText -Shape $shape -Text $Text -Size $Size -Bold $false
  return $shape
}

function Add-ActorDirect {
  param(
    $Diagram,
    [double]$Left,
    [double]$Top,
    [string]$Name
  )

  $head = Add-DiagramBox -Diagram $Diagram -Type $msoShapeOval -Left ($Left + 10) -Top $Top -Width 18 -Height 18 -Text '' -Size 10
  $head.TextFrame.TextRange.Text = ''
  Add-DiagramLine -Diagram $Diagram -X1 ($Left + 19) -Y1 ($Top + 18) -X2 ($Left + 19) -Y2 ($Top + 48) | Out-Null
  Add-DiagramLine -Diagram $Diagram -X1 ($Left + 6) -Y1 ($Top + 28) -X2 ($Left + 32) -Y2 ($Top + 28) | Out-Null
  Add-DiagramLine -Diagram $Diagram -X1 ($Left + 19) -Y1 ($Top + 48) -X2 ($Left + 8) -Y2 ($Top + 66) | Out-Null
  Add-DiagramLine -Diagram $Diagram -X1 ($Left + 19) -Y1 ($Top + 48) -X2 ($Left + 30) -Y2 ($Top + 66) | Out-Null
  Add-DiagramText -Diagram $Diagram -Left ($Left - 8) -Top ($Top + 70) -Width 60 -Height 18 -Text $Name -Size 9.5 | Out-Null
}

function Add-CanvasBox {
  param(
    $Canvas,
    [int]$Type,
    [double]$Left,
    [double]$Top,
    [double]$Width,
    [double]$Height,
    [string]$Text,
    [double]$Size = 10.5,
    [bool]$Bold = $false
  )

  $shape = $Canvas.CanvasItems.AddShape($Type, $Left, $Top, $Width, $Height)
  Format-ShapeText -Shape $shape -Text $Text -Size $Size -Bold $Bold
  return $shape
}

function Add-CanvasLine {
  param(
    $Canvas,
    [double]$X1,
    [double]$Y1,
    [double]$X2,
    [double]$Y2
  )

  $line = $Canvas.CanvasItems.AddLine($X1, $Y1, $X2, $Y2)
  $line.Line.ForeColor.RGB = 0
  return $line
}

function Add-CanvasText {
  param(
    $Canvas,
    [double]$Left,
    [double]$Top,
    [double]$Width,
    [double]$Height,
    [string]$Text,
    [double]$Size = 9.5
  )

  $shape = $Canvas.CanvasItems.AddTextBox(1, $Left, $Top, $Width, $Height)
  $shape.Line.Visible = $msoFalse
  $shape.Fill.Visible = $msoFalse
  Format-ShapeText -Shape $shape -Text $Text -Size $Size -Bold $false
  return $shape
}

function Add-Actor {
  param(
    $Canvas,
    [double]$Left,
    [double]$Top,
    [string]$Name
  )

  $head = $Canvas.CanvasItems.AddShape($msoShapeOval, $Left + 10, $Top, 18, 18)
  $head.Fill.Visible = $msoFalse
  $head.Line.Visible = $msoTrue
  $head.Line.ForeColor.RGB = 0
  Add-CanvasLine -Canvas $Canvas -X1 ($Left + 19) -Y1 ($Top + 18) -X2 ($Left + 19) -Y2 ($Top + 48) | Out-Null
  Add-CanvasLine -Canvas $Canvas -X1 ($Left + 6) -Y1 ($Top + 28) -X2 ($Left + 32) -Y2 ($Top + 28) | Out-Null
  Add-CanvasLine -Canvas $Canvas -X1 ($Left + 19) -Y1 ($Top + 48) -X2 ($Left + 8) -Y2 ($Top + 66) | Out-Null
  Add-CanvasLine -Canvas $Canvas -X1 ($Left + 19) -Y1 ($Top + 48) -X2 ($Left + 30) -Y2 ($Top + 66) | Out-Null
  Add-CanvasText -Canvas $Canvas -Left ($Left - 8) -Top ($Top + 70) -Width 60 -Height 18 -Text $Name -Size 9.5 | Out-Null
}

function Draw-FunctionModuleDiagram {
  param($Document, $Selection)

  $diagram = New-DiagramContext -Document $Document -Selection $Selection -Width 420 -Height 210
  Add-DiagramBox -Diagram $diagram -Type $msoShapeRoundedRectangle -Left 135 -Top 10 -Width 150 -Height 30 -Text '私有化共享相册平台' -Size 11 -Bold $true | Out-Null
  Add-DiagramLine -Diagram $diagram -X1 210 -Y1 40 -X2 210 -Y2 58 | Out-Null
  Add-DiagramLine -Diagram $diagram -X1 40 -Y1 58 -X2 380 -Y2 58 | Out-Null

  $boxes = @(
    @{ L = 10;  T = 78; Text = "用户认证与用户中心模块`r登录认证 / 用户设置 / 用户管理" }
    @{ L = 92;  T = 78; Text = "照片库模块`r时间线浏览 / 资源上传 / 状态维护" }
    @{ L = 174; T = 78; Text = "相册模块`r相册创建 / 资源入册 / 成员管理" }
    @{ L = 256; T = 78; Text = "共享协作模块`r共享链接 / 密码访问 / 伙伴共享" }
    @{ L = 338; T = 78; Text = "检索与地图模块`r条件检索 / 标签浏览 / 地图地点" }
  )

  foreach ($box in $boxes) {
    Add-DiagramLine -Diagram $diagram -X1 ($box.L + 35) -Y1 58 -X2 ($box.L + 35) -Y2 78 | Out-Null
    Add-DiagramBox -Diagram $diagram -Type $msoShapeRectangle -Left $box.L -Top $box.T -Width 70 -Height 66 -Text $box.Text -Size 8.5 -Bold $false | Out-Null
  }

  Reset-SelectionToDiagramAnchor -Selection $Selection -Diagram $diagram
  Add-BlankParagraphs -Selection $Selection -Count 14
}

function Draw-ActivityDiagram {
  param($Document, $Selection)

  $diagram = New-DiagramContext -Document $Document -Selection $Selection -Width 360 -Height 360
  Add-DiagramBox -Diagram $diagram -Type $msoShapeOval -Left 145 -Top 6 -Width 70 -Height 24 -Text '开始' -Size 10 | Out-Null

  $steps = @(
    @{ Y = 42;  Text = '登录系统' }
    @{ Y = 84;  Text = '浏览或上传资源' }
    @{ Y = 126; Text = '整理资源状态' }
    @{ Y = 168; Text = '管理相册' }
    @{ Y = 210; Text = '发起共享' }
    @{ Y = 252; Text = '访问共享资源' }
    @{ Y = 294; Text = '检索与定位资源' }
  )

  $lastCenterY = 30
  foreach ($step in $steps) {
    Add-DiagramLine -Diagram $diagram -X1 180 -Y1 $lastCenterY -X2 180 -Y2 $step.Y | Out-Null
    Add-DiagramBox -Diagram $diagram -Type $msoShapeRoundedRectangle -Left 105 -Top $step.Y -Width 150 -Height 26 -Text $step.Text -Size 10 | Out-Null
    $lastCenterY = $step.Y + 26
  }

  Add-DiagramLine -Diagram $diagram -X1 180 -Y1 $lastCenterY -X2 180 -Y2 328 | Out-Null
  Add-DiagramBox -Diagram $diagram -Type $msoShapeOval -Left 145 -Top 328 -Width 70 -Height 24 -Text '结束' -Size 10 | Out-Null
  Reset-SelectionToDiagramAnchor -Selection $Selection -Diagram $diagram
  Add-BlankParagraphs -Selection $Selection -Count 20
}

function Draw-ERDiagram {
  param($Document, $Selection)

  $diagram = New-DiagramContext -Document $Document -Selection $Selection -Width 430 -Height 250
  Add-DiagramBox -Diagram $diagram -Type $msoShapeRectangle -Left 20  -Top 20  -Width 72 -Height 28 -Text 'user' -Size 10 -Bold $true | Out-Null
  Add-DiagramBox -Diagram $diagram -Type $msoShapeRectangle -Left 20  -Top 78  -Width 72 -Height 28 -Text 'session' -Size 10 -Bold $true | Out-Null
  Add-DiagramBox -Diagram $diagram -Type $msoShapeRectangle -Left 128 -Top 20  -Width 78 -Height 28 -Text 'asset' -Size 10 -Bold $true | Out-Null
  Add-DiagramBox -Diagram $diagram -Type $msoShapeRectangle -Left 128 -Top 78  -Width 78 -Height 28 -Text 'album' -Size 10 -Bold $true | Out-Null
  Add-DiagramBox -Diagram $diagram -Type $msoShapeRectangle -Left 128 -Top 136 -Width 78 -Height 28 -Text 'shared_link' -Size 9 -Bold $true | Out-Null
  Add-DiagramBox -Diagram $diagram -Type $msoShapeRectangle -Left 128 -Top 194 -Width 78 -Height 28 -Text 'tag' -Size 10 -Bold $true | Out-Null
  Add-DiagramBox -Diagram $diagram -Type $msoShapeRectangle -Left 264 -Top 35  -Width 92 -Height 28 -Text 'asset_file' -Size 9 -Bold $true | Out-Null
  Add-DiagramBox -Diagram $diagram -Type $msoShapeRectangle -Left 264 -Top 93  -Width 92 -Height 28 -Text 'asset_exif' -Size 9 -Bold $true | Out-Null

  Add-DiagramLine -Diagram $diagram -X1 92 -Y1 34 -X2 128 -Y2 34 | Out-Null
  Add-DiagramText -Diagram $diagram -Left 98 -Top 16 -Width 28 -Height 14 -Text '1..n' -Size 8.5 | Out-Null
  Add-DiagramLine -Diagram $diagram -X1 56 -Y1 48 -X2 56 -Y2 78 | Out-Null
  Add-DiagramText -Diagram $diagram -Left 60 -Top 56 -Width 30 -Height 14 -Text '1..n' -Size 8.5 | Out-Null
  Add-DiagramLine -Diagram $diagram -X1 92 -Y1 90 -X2 128 -Y2 92 | Out-Null
  Add-DiagramText -Diagram $diagram -Left 97 -Top 95 -Width 28 -Height 14 -Text '1..n' -Size 8.5 | Out-Null
  Add-DiagramLine -Diagram $diagram -X1 92 -Y1 34 -X2 128 -Y2 92 | Out-Null
  Add-DiagramLine -Diagram $diagram -X1 92 -Y1 34 -X2 128 -Y2 150 | Out-Null
  Add-DiagramLine -Diagram $diagram -X1 92 -Y1 34 -X2 128 -Y2 208 | Out-Null
  Add-DiagramLine -Diagram $diagram -X1 206 -Y1 34 -X2 264 -Y2 49 | Out-Null
  Add-DiagramText -Diagram $diagram -Left 214 -Top 18 -Width 46 -Height 14 -Text '关联文件' -Size 8.5 | Out-Null
  Add-DiagramLine -Diagram $diagram -X1 206 -Y1 34 -X2 264 -Y2 107 | Out-Null
  Add-DiagramText -Diagram $diagram -Left 212 -Top 74 -Width 54 -Height 14 -Text '扩展元数据' -Size 8.5 | Out-Null
  Add-DiagramLine -Diagram $diagram -X1 206 -Y1 34 -X2 206 -Y2 92 | Out-Null
  Add-DiagramText -Diagram $diagram -Left 210 -Top 54 -Width 46 -Height 14 -Text '通过album_asset' -Size 7.5 | Out-Null
  Add-DiagramLine -Diagram $diagram -X1 206 -Y1 34 -X2 206 -Y2 150 | Out-Null
  Add-DiagramText -Diagram $diagram -Left 210 -Top 115 -Width 58 -Height 14 -Text '通过shared_link_asset' -Size 7 | Out-Null
  Add-DiagramLine -Diagram $diagram -X1 206 -Y1 34 -X2 206 -Y2 208 | Out-Null
  Add-DiagramText -Diagram $diagram -Left 210 -Top 175 -Width 42 -Height 14 -Text '通过tag_asset' -Size 7.5 | Out-Null
  Reset-SelectionToDiagramAnchor -Selection $Selection -Diagram $diagram
  Add-BlankParagraphs -Selection $Selection -Count 16
}

function Draw-UseCaseDiagram {
  param($Document, $Selection)

  $diagram = New-DiagramContext -Document $Document -Selection $Selection -Width 430 -Height 290
  Add-DiagramBox -Diagram $diagram -Type $msoShapeRectangle -Left 95 -Top 10 -Width 315 -Height 250 -Text '私有化共享相册平台' -Size 10 -Bold $true | Out-Null
  Add-ActorDirect -Diagram $diagram -Left 18 -Top 30  -Name '管理员'
  Add-ActorDirect -Diagram $diagram -Left 18 -Top 110 -Name '注册用户'
  Add-ActorDirect -Diagram $diagram -Left 18 -Top 205 -Name '共享访问者'

  $usecases = @(
    @{ L = 130; T = 34;  W = 88; H = 28; Text = '登录系统' }
    @{ L = 260; T = 34;  W = 120; H = 28; Text = '管理用户信息' }
    @{ L = 130; T = 92;  W = 120; H = 30; Text = '上传与管理资源' }
    @{ L = 270; T = 92;  W = 88; H = 30; Text = '管理相册' }
    @{ L = 130; T = 152; W = 120; H = 30; Text = '创建共享链接' }
    @{ L = 270; T = 152; W = 110; H = 30; Text = '访问共享资源' }
    @{ L = 180; T = 212; W = 130; H = 30; Text = '检索与定位资源' }
  )

  foreach ($uc in $usecases) {
    Add-DiagramBox -Diagram $diagram -Type $msoShapeOval -Left $uc.L -Top $uc.T -Width $uc.W -Height $uc.H -Text $uc.Text -Size 9.5 | Out-Null
  }

  Add-DiagramLine -Diagram $diagram -X1 52 -Y1 48  -X2 130 -Y2 48  | Out-Null
  Add-DiagramLine -Diagram $diagram -X1 52 -Y1 48  -X2 260 -Y2 48  | Out-Null
  Add-DiagramLine -Diagram $diagram -X1 52 -Y1 128 -X2 130 -Y2 107 | Out-Null
  Add-DiagramLine -Diagram $diagram -X1 52 -Y1 128 -X2 270 -Y2 107 | Out-Null
  Add-DiagramLine -Diagram $diagram -X1 52 -Y1 128 -X2 130 -Y2 167 | Out-Null
  Add-DiagramLine -Diagram $diagram -X1 52 -Y1 128 -X2 180 -Y2 227 | Out-Null
  Add-DiagramLine -Diagram $diagram -X1 52 -Y1 223 -X2 270 -Y2 167 | Out-Null
  Reset-SelectionToDiagramAnchor -Selection $Selection -Diagram $diagram
  Add-BlankParagraphs -Selection $Selection -Count 18
}

function Add-Figure {
  param(
    $Document,
    $Selection,
    [string]$Type,
    [ref]$FigureIndex
  )

  $FigureIndex.Value++
  switch ($Type) {
    'FUNCTION_MODULE' {
      Draw-FunctionModuleDiagram -Document $Document -Selection $Selection
      Add-CaptionParagraph -Selection $Selection -Text ("图2-{0} 系统功能模块图" -f $FigureIndex.Value)
    }
    'ACTIVITY' {
      Draw-ActivityDiagram -Document $Document -Selection $Selection
      Add-CaptionParagraph -Selection $Selection -Text ("图2-{0} 系统整体业务活动图" -f $FigureIndex.Value)
    }
    'ER' {
      Draw-ERDiagram -Document $Document -Selection $Selection
      Add-CaptionParagraph -Selection $Selection -Text ("图2-{0} 系统E-R图" -f $FigureIndex.Value)
    }
    'USECASE' {
      Draw-UseCaseDiagram -Document $Document -Selection $Selection
      Add-CaptionParagraph -Selection $Selection -Text ("图2-{0} 系统用例图" -f $FigureIndex.Value)
    }
  }
}

function Format-TableCell {
  param(
    $Cell,
    [string]$Text,
    [bool]$Bold = $false,
    [int]$Alignment = $wdAlignParagraphLeft,
    [double]$Size = 10.5
  )

  $range = $Cell.Range
  $range.Text = $Text
  $range.Font.NameFarEast = '宋体'
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

function Join-ItemLines {
  param($Value)

  if ($Value -is [System.Array]) {
    return ($Value -join "`r")
  }

  return [string]$Value
}

function Split-MarkdownTableRow {
  param([string]$Line)

  $trimmed = $Line.Trim()
  if ($trimmed.StartsWith('|')) {
    $trimmed = $trimmed.Substring(1)
  }
  if ($trimmed.EndsWith('|')) {
    $trimmed = $trimmed.Substring(0, $trimmed.Length - 1)
  }

  $cells = $trimmed -split '(?<!\\)\|'
  $result = @()
  foreach ($cell in $cells) {
    $result += (Convert-MarkdownText -Text (($cell -replace '\\\|', '|').Trim()))
  }

  return ,$result
}

function Test-MarkdownTableSeparator {
  param([string]$Line)

  $trimmed = $Line.Trim()
  return $trimmed -match '^\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|?$'
}

function Add-MarkdownTable {
  param(
    $Document,
    $Selection,
    [object[]]$Rows
  )

  if (-not $Rows -or $Rows.Count -eq 0) {
    return
  }

  $columnCount = 0
  foreach ($row in $Rows) {
    if ($row.Count -gt $columnCount) {
      $columnCount = $row.Count
    }
  }

  if ($columnCount -le 0) {
    return
  }

  Reset-SelectionFormat -Selection $Selection
  $table = $Document.Tables.Add($Selection.Range, $Rows.Count, $columnCount)
  $table.Borders.Enable = 1
  $table.Rows.Alignment = $wdAlignParagraphCenter
  $table.AllowAutoFit = $true
  $table.AutoFitBehavior($wdAutoFitWindow)

  for ($r = 0; $r -lt $Rows.Count; $r++) {
    $row = $Rows[$r]
    for ($c = 0; $c -lt $columnCount; $c++) {
      $cellText = if ($c -lt $row.Count) { [string]$row[$c] } else { '' }
      $alignment = if ($r -eq 0 -or $c -eq 0 -or $c -eq ($columnCount - 1)) { $wdAlignParagraphCenter } else { $wdAlignParagraphLeft }
      $isBold = ($r -eq 0)
      $fontSize = if ($r -eq 0) { 10 } else { 9.5 }
      Format-TableCell -Cell $table.Cell($r + 1, $c + 1) -Text $cellText -Bold $isBold -Alignment $alignment -Size $fontSize
    }
  }

  $Selection.SetRange($table.Range.End, $table.Range.End)
  $Selection.TypeParagraph()
}

function Add-UseCaseTable {
  param(
    $Document,
    $Selection,
    [string]$Key,
    [ref]$TableIndex
  )

  $spec = $tableSpecs[$Key]
  if (-not $spec) {
    throw "未知用例表标识: $Key"
  }

  $TableIndex.Value++
  Add-CaptionParagraph -Selection $Selection -Text ("表2-{0} {1}用例规约表" -f $TableIndex.Value, $spec.Name)
  Reset-SelectionFormat -Selection $Selection
  $table = $Document.Tables.Add($Selection.Range, 11, 4)
  $table.Borders.Enable = 1
  $table.Columns.Item(1).Width = 66
  $table.Columns.Item(2).Width = 90
  $table.Columns.Item(3).Width = 66
  $table.Columns.Item(4).Width = 170

  Format-TableCell -Cell $table.Cell(1, 1) -Text '用例编号' -Bold $true -Alignment $wdAlignParagraphCenter
  Format-TableCell -Cell $table.Cell(1, 2) -Text $spec.Number -Alignment $wdAlignParagraphCenter
  Format-TableCell -Cell $table.Cell(1, 3) -Text '用例名称' -Bold $true -Alignment $wdAlignParagraphCenter
  Format-TableCell -Cell $table.Cell(1, 4) -Text $spec.Name -Alignment $wdAlignParagraphCenter

  $rows = @(
    @{ Row = 2; Label = '功能描述'; Value = $spec.Description }
    @{ Row = 3; Label = '执行者'; Value = $spec.Actor }
    @{ Row = 4; Label = '前置条件'; Value = $spec.Precondition }
    @{ Row = 5; Label = '后置条件'; Value = $spec.Postcondition }
    @{ Row = 6; Label = '涉众利益'; Value = $spec.Stakeholders }
    @{ Row = 7; Label = '基本路径'; Value = (Join-ItemLines -Value $spec.BasicPath) }
    @{ Row = 8; Label = '扩展路径'; Value = (Join-ItemLines -Value $spec.ExtensionPath) }
    @{ Row = 9; Label = '字段列表'; Value = $spec.Fields }
    @{ Row = 10; Label = '业务规则'; Value = $spec.Rules }
    @{ Row = 11; Label = '备注'; Value = $spec.Remark }
  )

  foreach ($item in $rows) {
    Format-TableCell -Cell $table.Cell($item.Row, 1) -Text $item.Label -Bold $true -Alignment $wdAlignParagraphCenter
    $table.Cell($item.Row, 2).Merge($table.Cell($item.Row, 4))
    Format-TableCell -Cell $table.Cell($item.Row, 2) -Text $item.Value -Alignment $wdAlignParagraphLeft
  }

  $Selection.SetRange($table.Range.End, $table.Range.End)
  $Selection.TypeParagraph()
}

function Parse-ChapterMarkdown {
  param(
    $Document,
    $Selection,
    [string]$Path
  )

  $raw = Get-Content -Raw -Encoding utf8 $Path
  $lines = ($raw -replace "`r`n", "`n") -split "`n"
  $figureIndex = 0
  $tableIndex = 0

  for ($i = 0; $i -lt $lines.Count; $i++) {
    $text = $lines[$i].TrimEnd()
    if ([string]::IsNullOrWhiteSpace($text)) {
      continue
    }

    if ($text -match '^#\s+(.+)$') {
      Add-Heading -Selection $Selection -Level 1 -Text (Convert-MarkdownText -Text $matches[1])
      continue
    }

    if ($text -match '^##\s+(.+)$') {
      Add-Heading -Selection $Selection -Level 1 -Text (Convert-MarkdownText -Text $matches[1])
      continue
    }

    if ($text -match '^###\s+(.+)$') {
      Add-Heading -Selection $Selection -Level 2 -Text (Convert-MarkdownText -Text $matches[1])
      continue
    }

    if ($text -match '^####\s+(.+)$') {
      Add-Heading -Selection $Selection -Level 3 -Text (Convert-MarkdownText -Text $matches[1])
      continue
    }

    if ($text -match '^\[\[DRAW:(.+)\]\]$') {
      Add-Figure -Document $Document -Selection $Selection -Type $matches[1] -FigureIndex ([ref]$figureIndex)
      continue
    }

    if ($text -match '^\[\[TABLE:(.+)\]\]$') {
      Add-UseCaseTable -Document $Document -Selection $Selection -Key $matches[1] -TableIndex ([ref]$tableIndex)
      continue
    }

    if ($i + 1 -lt $lines.Count -and $text.Trim().StartsWith('|') -and (Test-MarkdownTableSeparator -Line $lines[$i + 1])) {
      $rows = @()
      $rows += ,(Split-MarkdownTableRow -Line $text)
      $i += 2
      while ($i -lt $lines.Count) {
        $rowText = $lines[$i].Trim()
        if ([string]::IsNullOrWhiteSpace($rowText)) {
          break
        }
        if (-not $rowText.StartsWith('|')) {
          $i--
          break
        }
        $rows += ,(Split-MarkdownTableRow -Line $rowText)
        $i++
      }
      Add-MarkdownTable -Document $Document -Selection $Selection -Rows $rows
      continue
    }

    if ($text -match '^>\s+(.+)$') {
      Add-BodyParagraph -Selection $Selection -Text $matches[1]
      continue
    }

    if ($text -match '^[-*]\s+(.+)$') {
      Add-BodyParagraph -Selection $Selection -Text ("• " + $matches[1])
      continue
    }

    if ($text -match '^---+$') {
      continue
    }

    Add-BodyParagraph -Selection $Selection -Text $text
  }
}

if (-not (Test-Path $MarkdownPath)) {
  throw "Markdown 文件不存在: $MarkdownPath"
}

$outputDirectory = Split-Path -Parent $OutputPath
if (-not (Test-Path $outputDirectory)) {
  New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
}

$word = $null
$document = $null

try {
  $word = New-Object -ComObject Word.Application
  $word.Visible = $false
  $word.DisplayAlerts = 0
  Write-Output 'WORD_STARTED'
  $document = $word.Documents.Add()
  Write-Output 'DOC_CREATED'
  Configure-DocumentStyles -Document $document
  Set-PageSetup -Section $document.Sections.Item(1) -Landscape:$Landscape
  Set-PageNumbers -Document $document

  $selection = $word.Selection
  Reset-SelectionFormat -Selection $selection
  Parse-ChapterMarkdown -Document $document -Selection $selection -Path $MarkdownPath
  Write-Output 'PARSE_COMPLETE'

  $document.Fields.Update() | Out-Null
  Write-Output 'FIELDS_UPDATED'
  $saveFormat = if ([System.IO.Path]::GetExtension($OutputPath).ToLowerInvariant() -eq '.doc') { $wdFormatDocument97 } else { $wdFormatXMLDocument }
  $document.SaveAs([ref]$OutputPath, [ref]$saveFormat)
  Write-Output 'SAVED'
  Write-Output ("WORD_DOCUMENT_CREATED: {0}" -f $OutputPath)
}
catch {
  Write-Output ("ERROR_MSG: {0}" -f $_.Exception.Message)
  Write-Output ("ERROR_POS: {0}" -f $_.InvocationInfo.PositionMessage)
  throw
}
finally {
  if ($document -ne $null) {
    Write-Output 'CLOSING_DOC'
    $document.Close()
  }
  if ($word -ne $null) {
    Write-Output 'QUITTING_WORD'
    $word.Quit()
  }
  [System.GC]::Collect()
  [System.GC]::WaitForPendingFinalizers()
}


