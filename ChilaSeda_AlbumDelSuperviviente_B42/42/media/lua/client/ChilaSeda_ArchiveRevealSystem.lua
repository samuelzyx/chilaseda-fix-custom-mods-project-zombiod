-- Sistema de animacion de "destapado" tipo Panini/Pepsicards
-- Las estampitas se revelan progresivamente cuando se descubren

local REVEAL_DURATION = 0.8  -- segundos
local REVEAL_TEXTURE = "media/gfx/sticker_unrevealed.png"

local function currentSeconds()
	return getTimestampMs() / 1000
end

local RevealOverlay = ISPanel:derive("ChilaSedaRevealOverlay")

function RevealOverlay:new(playerNum, record, x, y, width, height)
	local window = ISPanel.new(self, x, y, width, height)
	window.playerNum = playerNum
	window.record = record
	window.startTime = currentSeconds()
	window.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
	window.borderColor = { r = 0, g = 0, b = 0, a = 0 }
	window.drawBorder = false
	return window
end

function RevealOverlay:initialise()
	ISPanel.initialise(self)
end

function RevealOverlay:render()
	ISPanel.render(self)

	local elapsed = currentSeconds() - self.startTime
	local progress = math.min(elapsed / REVEAL_DURATION, 1.0)

	if progress < 1.0 then
		local texture = getTexture(REVEAL_TEXTURE)
		if texture then
			-- Efecto de revelacion: comienza desde arriba, va hacia abajo
			local revealHeight = self.height * (1.0 - progress)

			-- Dibujar overlay gris oscuro que se desvanece
			self:drawRect(0, 0, self.width, self.height, 0.2, 0.7, 0.7, 0.7)

			-- Overlay de destapado que baja
			if revealHeight > 0 then
				self:drawTextureScaled(texture, 0, 0, self.width, revealHeight, 0.8)
			end

			-- Particulas/brillo en la linea de revelacion
			if progress > 0.2 and progress < 0.9 then
				local sparkY = revealHeight + 5
				local sparkOpacity = math.sin(progress * math.pi) * 0.6
				self:drawRect(0, sparkY - 2, self.width, 4, 0.3, 1.0, 1.0, 0.7)
			end
		end
	else
		-- Revelacion completada - remover del UI
		self:setVisible(false)
		self:removeFromUIManager()
	end
end

function RevealOverlay:onMouseDown(x, y)
	-- Click para acelerar revelacion
	if self.startTime then
		self.startTime = currentSeconds() - (REVEAL_DURATION * 0.9)
	end
	return true
end

local RevealGalleryPanel = ISPanel:derive("ChilaSedaRevealGalleryPanel")

function RevealGalleryPanel:new(playerNum, records, categoryId)
	local width, height = 1000, 700
	local x = (getCore():getScreenWidth() - width) / 2
	local y = (getCore():getScreenHeight() - height) / 2
	local window = ISPanel.new(self, x, y, width, height)
	window.playerNum = playerNum
	window.records = records or {}
	window.categoryId = categoryId
	window.backgroundColor = { r = 0.08, g = 0.07, b = 0.06, a = 0.96 }
	window.borderColor = { r = 0.75, g = 0.59, b = 0.35, a = 1 }
	window.itemsPerRow = 4
	window.cardWidth = 180
	window.cardHeight = 240
	window.padding = 20
	window.currentPage = 1
	window.activateReveal = {}
	return window
end

function RevealGalleryPanel:initialise()
	ISPanel.initialise(self)
end

function RevealGalleryPanel:createChildren()
	local margin = 18
	local titleLabel = ISLabel:new(margin, 14, 26, "Galeria de Coleccionables", 0.95, 0.82, 0.57, 1, UIFont.Medium, false)
	titleLabel:initialise()
	self:addChild(titleLabel)

	self.previousButton = ISButton:new(margin, self.height - 52, 100, 32, "Anterior", self, RevealGalleryPanel.onPreviousPage)
	self.previousButton:initialise()
	self:addChild(self.previousButton)

	self.nextButton = ISButton:new(margin + 110, self.height - 52, 100, 32, "Siguiente", self, RevealGalleryPanel.onNextPage)
	self.nextButton:initialise()
	self:addChild(self.nextButton)

	self.closeButton = ISButton:new(self.width - 92, self.height - 52, 74, 32, "Cerrar", self, RevealGalleryPanel.onClose)
	self.closeButton:initialise()
	self:addChild(self.closeButton)
end

function RevealGalleryPanel:render()
	ISPanel.render(self)
	self:drawCards()
end

function RevealGalleryPanel:drawCards()
	local startIdx = (self.currentPage - 1) * (self.itemsPerRow * 2) + 1
	local endIdx = math.min(startIdx + (self.itemsPerRow * 2) - 1, #self.records)

	local x, y = 20, 60
	local col = 0

	for i = startIdx, endIdx do
		local record = self.records[i]
		if record then
			-- Marco de estampita
			self:drawRect(x, y, self.cardWidth, self.cardHeight, 0.2, 0.4, 0.3, 0.2)
			self:drawRectBorder(x, y, self.cardWidth, self.cardHeight, 1, 0.6, 0.5, 0.3)

			-- Titulo
			local title = recordTitle and recordTitle(record) or record.id
			self:drawText(title, x + 5, y + 5, 0.8, 0.8, 0.7, 0.9, UIFont.Small)

			-- Efecto de hover si se puede revelar
			if not self.activateReveal[record.id] then
				self:drawText("[Click para revelar]", x + 5, y + self.cardHeight - 30, 0.9, 0.8, 0.4, 0.7, UIFont.Small)
			else
				self:drawText("[Descubierto]", x + 5, y + self.cardHeight - 30, 1.0, 0.9, 0.5, 0.8, UIFont.Small)
			end

			col = col + 1
			x = x + self.cardWidth + self.padding

			if col >= self.itemsPerRow then
				col = 0
				x = 20
				y = y + self.cardHeight + self.padding
			end
		end
	end
end

function RevealGalleryPanel:onMouseDown(x, y)
	-- Detectar clic en tarjetas
	local startIdx = (self.currentPage - 1) * (self.itemsPerRow * 2) + 1
	local endIdx = math.min(startIdx + (self.itemsPerRow * 2) - 1, #self.records)

	local cardX, cardY = 20, 60
	local col = 0

	for i = startIdx, endIdx do
		local record = self.records[i]
		if record then
			if x >= cardX and x <= cardX + self.cardWidth and y >= cardY and y <= cardY + self.cardHeight then
				-- Click en esta tarjeta
				self:triggerReveal(record, cardX, cardY)
				return true
			end

			col = col + 1
			cardX = cardX + self.cardWidth + self.padding

			if col >= self.itemsPerRow then
				col = 0
				cardX = 20
				cardY = cardY + self.cardHeight + self.padding
			end
		end
	end

	return ISPanel.onMouseDown(self, x, y)
end

function RevealGalleryPanel:triggerReveal(record, x, y)
	if self.activateReveal[record.id] then return end

	-- Marcar como revelado
	self.activateReveal[record.id] = true

	-- Crear overlay de animacion
	local overlay = RevealOverlay:new(self.playerNum, record, self.x + x, self.y + y, self.cardWidth, self.cardHeight)
	overlay:initialise()
	overlay:addToUIManager()
	overlay:setVisible(true)

	-- Sonido de revelacion
	local soundManager = getSoundManager()
	if soundManager then
		soundManager:playUISound("UINotificationTick")
	end
end

function RevealGalleryPanel:onPreviousPage()
	if self.currentPage > 1 then
		self.currentPage = self.currentPage - 1
	end
end

function RevealGalleryPanel:onNextPage()
	local maxPages = math.ceil(#self.records / (self.itemsPerRow * 2))
	if self.currentPage < maxPages then
		self.currentPage = self.currentPage + 1
	end
end

function RevealGalleryPanel:onClose()
	self:setVisible(false)
	self:removeFromUIManager()
end

local function openRevealGallery(playerNum, categoryId, records)
	local gallery = RevealGalleryPanel:new(playerNum, records, categoryId)
	gallery:initialise()
	gallery:createChildren()
	gallery:addToUIManager()
	gallery:setVisible(true)
	gallery:bringToTop()
end

return {
	openRevealGallery = openRevealGallery,
	RevealGalleryPanel = RevealGalleryPanel,
	RevealOverlay = RevealOverlay,
}
