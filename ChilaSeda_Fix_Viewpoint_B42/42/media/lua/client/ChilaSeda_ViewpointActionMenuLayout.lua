local TAG = "[ChilaSeda_ViewpointActionMenuLayout] "

local function splitLines(text)
	local lines = {}
	for line in (tostring(text or ""):gsub("\r", "") .. "\n"):gmatch("(.-)\n") do
		lines[#lines + 1] = line
	end
	if #lines == 0 then lines[1] = "" end
	return lines
end

local function wrapText(text, font, maxWidth, theme)
	local wrapped = {}
	for _, sourceLine in ipairs(splitLines(text)) do
		local line = ""
		for word in sourceLine:gmatch("%S+") do
			local candidate = line == "" and word or (line .. " " .. word)
			if line ~= "" and theme.textWidth(font, candidate) > maxWidth then
				wrapped[#wrapped + 1] = line
				line = word
			else
				line = candidate
			end
		end
		wrapped[#wrapped + 1] = line
	end
	return wrapped
end

local function install()
	local menu = ViewpointUI and ViewpointUI.UI and ViewpointUI.UI.VPActionMenu
	local theme = ViewpointUI and ViewpointUI.UI and ViewpointUI.UI.Theme
	local util = ViewpointUI and ViewpointUI.Util
	if not menu or not theme or not util or menu.ChilaSedaMultilineLayout then return false end

	menu.layout = function(self)
		local font = theme.font()
		local small = theme.smallFont()
		local padX, padY = theme.px(10), theme.px(7)
		local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
		local maxBoxWidth = math.max(theme.px(190), math.floor(sw * 0.46))
		local maxTextWidth = maxBoxWidth - padX * 2 - theme.px(14)
		local lineH = theme.fontHeight(font) + theme.px(2)
		local rowPad = theme.px(7)
		local rows, textWidth = {}, theme.px(136)
		for i, item in ipairs(self.items or {}) do
			local lines = wrapText(item.label, font, maxTextWidth, theme)
			rows[i] = { lines = lines, height = math.max(theme.fontHeight(font) + rowPad,
				#lines * lineH + rowPad) }
			for _, line in ipairs(lines) do
				textWidth = math.max(textWidth, theme.textWidth(font, line))
			end
		end
		local titleLines = self.title and wrapText(self.title, small, maxTextWidth, theme) or {}
		local footerLines = self.footer and wrapText(self.footer, small, maxTextWidth, theme) or {}
		for _, line in ipairs(titleLines) do textWidth = math.max(textWidth, theme.textWidth(small, line)) end
		for _, line in ipairs(footerLines) do textWidth = math.max(textWidth, theme.textWidth(small, line)) end
		local titleLineH, footerLineH = theme.fontHeight(small) + theme.px(2), theme.fontHeight(small) + theme.px(2)
		local titleH = #titleLines > 0 and (#titleLines * titleLineH + theme.px(6)) or 0
		local footH = #footerLines > 0 and (#footerLines * footerLineH + theme.px(8)) or 0
		local rowsH = 0
		for _, row in ipairs(rows) do rowsH = rowsH + row.height end
		local w = math.min(maxBoxWidth, textWidth + padX * 2 + theme.px(14))
		local h = rowsH + padY * 2 + titleH + footH
		self.box = { w = w, h = h, padX = padX, padY = padY, rows = rows,
			titleLines = titleLines, footerLines = footerLines,
			lineH = lineH, titleLineH = titleLineH, footerLineH = footerLineH,
			titleH = titleH, footH = footH }
		local cx, cy = theme.screenCenter()
		local x = math.min(cx + theme.px(36), sw - w - theme.px(8))
		local y = util.clamp(cy - math.floor(h / 2), theme.px(8),
			math.max(theme.px(8), sh - h - theme.px(8)))
		self:place(x, y, w, h)
		self.dirty = false
	end

	menu.render = function(self)
		if self.dirty then self:layout() end
		local b = self.box
		local font, small = theme.font(), theme.smallFont()
		local colors = theme.color
		local C = colors
		self:panel(0, 0, b.w, b.h)
		local y = b.padY
		for _, line in ipairs(b.titleLines) do
			self:text(line, b.padX, y, C.dim, small)
			y = y + b.titleLineH
		end
		if #b.titleLines > 0 then
			self:fill(b.padX, y - theme.px(4), b.w - b.padX * 2, 1, C.edge, 1.5)
			y = b.padY + b.titleH
		end
		for i, item in ipairs(self.items or {}) do
			local row = b.rows[i]
			local enabled = item.enabled ~= false
			if i == self.selected and enabled then
				self:fill(theme.px(3), y, b.w - theme.px(6), row.height - theme.px(1), C.panelHi)
				self:fill(theme.px(3), y, theme.px(2), row.height - theme.px(1), C.accent)
			end
			local color = enabled and (i == self.selected and C.text or C.dim) or C.off
			local textY = y + math.floor((row.height - #row.lines * b.lineH) / 2)
			for _, line in ipairs(row.lines) do
				self:text(line, b.padX + theme.px(6), textY, color, font)
				textY = textY + b.lineH
			end
			y = y + row.height
		end
		if #b.footerLines > 0 then
			local footerY = b.h - b.padY - #b.footerLines * b.footerLineH
			for _, line in ipairs(b.footerLines) do
				self:text(line, b.padX, footerY, C.off, small)
				footerY = footerY + b.footerLineH
			end
		end
	end

	menu.ChilaSedaMultilineLayout = true
	print(TAG .. "multiline rows and footer installed")
	return true
end

if not install() then
	Events.OnGameStart.Add(install)
	Events.OnCreatePlayer.Add(install)
end
