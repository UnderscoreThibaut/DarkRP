/*---------------------------------------------------------------------------
Vote/become job button
---------------------------------------------------------------------------*/
local PANEL = {}

function PANEL:Init()
	self.BaseClass.Init(self)
	self:SetFont("F4MenuFont2")
	self:SetTall(50)
	self:SetTextColor(Color(255, 255, 255, 255))
end

function PANEL:setJob(job, closeFunc)
	if job.vote or job.RequiresVote and job.RequiresVote(LocalPlayer(), job.team) then
		self:SetText(DarkRP.getPhrase("create_vote_for_job"))
		self.DoClick = fn.Compose{closeFunc, fn.Partial(RunConsoleCommand, "darkrp", "vote" .. job.command)}
	else
		self:SetText(DarkRP.getPhrase("become_job"))
		self.DoClick = fn.Compose{closeFunc, fn.Partial(RunConsoleCommand, "darkrp", job.command)}
	end
end

local red, dark = Color(140, 0, 0, 180), Color(0, 0, 0, 200)
function PANEL:Paint(w, h)
	draw.RoundedBox(4, 0, 0, w, h, dark)
	draw.RoundedBox(4, 5, 5, w - 10, h - 10, red)
end

derma.DefineControl("F4MenuJobBecomeButton", "", PANEL, "DButton")

/*---------------------------------------------------------------------------
Left panel for the jobs
---------------------------------------------------------------------------*/
PANEL = {}

function PANEL:Init()
	self:SetBackgroundColor(Color(0, 0, 0, 0))
	self:EnableVerticalScrollbar()
	self:SetSpacing(2)
	self.VBar.Paint = fn.Id
	self.VBar.btnUp.Paint = fn.Id
	self.VBar.btnDown.Paint = fn.Id
end

function PANEL:Refresh()
	for k,v in pairs(self.Items) do
		if v.Refresh then v:Refresh() end
	end
	self:InvalidateLayout()
end

derma.DefineControl("F4EmptyPanel", "", PANEL, "DPanelList")

/*---------------------------------------------------------------------------
Right panel for the jobs
---------------------------------------------------------------------------*/
PANEL = {}

function PANEL:Init()
	self.BaseClass.Init(self)
	self:SetPadding(10)

	self.lblTitle = vgui.Create("DLabel")
	self.lblTitle:SetFont("F4MenuFont2")
	self:AddItem(self.lblTitle)

	self.lblDescription = vgui.Create("DLabel")
	self.lblDescription:SetWide(self:GetWide() - 20)
	self.lblDescription:SetFont("Ubuntu Light")
	self.lblDescription:SetAutoStretchVertical(true)
	self:AddItem(self.lblDescription)

	self.filler = VGUIRect(0, 0, 0, 20)
	self.filler:SetColor(Color(0, 0, 0, 0))
	self:AddItem(self.filler)

	self.lblWeapons = vgui.Create("DLabel")
	self.lblWeapons:SetFont("F4MenuFont2")
	self.lblWeapons:SetText("Weapons")
	self.lblWeapons:SizeToContents()
	self.lblWeapons:SetTall(50)
	self:AddItem(self.lblWeapons)

	self.lblSweps = vgui.Create("DLabel")
	self.lblSweps:SetAutoStretchVertical(true)
	self.lblSweps:SetFont("Ubuntu Light")
	self:AddItem(self.lblSweps)

	self.btnGetJob = vgui.Create("F4MenuJobBecomeButton", self)
	self.btnGetJob:Dock(BOTTOM)

	self.job = {}
end

local black = Color(0, 0, 0, 170)
function PANEL:Paint(w, h)
	draw.RoundedBox(0, 0, 0, w, h, black)
end

-- functions for getting the weapon names from the job table
local getWepName = fn.FOr{fn.FAnd{weapons.Get, fn.Compose{fn.Curry(fn.GetValue, 2)("PrintName"), weapons.Get}}, fn.Id}
local getWeaponNames = fn.Curry(fn.Map, 2)(getWepName)
local weaponString = fn.Compose{fn.Curry(fn.Flip(table.concat), 2)("\n"), fn.Curry(fn.Seq, 2)(table.sort), getWeaponNames, table.Copy}
function PANEL:updateInfo(job)
	self.lblTitle:SetText(job.name)
	self.job = job

	self.lblTitle:SizeToContents()

	self.lblDescription:SetText(job.description)
	self.lblDescription:SizeToContents()

	local weps = weaponString(job.weapons)
	weps = weps ~= "" and weps or DarkRP.getPhrase("no_extra_weapons")

	self.lblSweps:SetText(weps)

	self.btnGetJob:setJob(job, fn.Partial(self:GetParent():GetParent().Hide, self:GetParent():GetParent()))

	self:InvalidateLayout()
end

derma.DefineControl("F4JobsPanelRight", "", PANEL, "F4EmptyPanel")


/*---------------------------------------------------------------------------
Jobs panel
---------------------------------------------------------------------------*/
PANEL = {}

function PANEL:Init()
	self.pnlLeft = vgui.Create("F4EmptyPanel", self)
	self.pnlLeft:Dock(LEFT)

	self.pnlRight = vgui.Create("F4JobsPanelRight", self)
	self.pnlRight:Dock(RIGHT)

	self:fillData()
end

function PANEL:PerformLayout()
	self.pnlLeft:SetWide(self:GetWide() * 2/3 - 5)
	self.pnlRight:SetWide(self:GetWide() * 1/3 - 5)
end

PANEL.Paint = fn.Id

-- If the following code is moved to Init, the gamemode will blow up.
function PANEL:SetParent(parent)
	self.BaseClass.SetParent(self, parent)
	local job
	for k, v in ipairs(self.pnlLeft:GetItems()) do
		if v:GetDisabled() then continue end
		job = v.DarkRPItem
		break
	end
	self.pnlRight:updateInfo(job or {})
end

function PANEL:Refresh()
	self.pnlLeft:Refresh()

	if not self.pnlLeft.Items then self.pnlRight:updateInfo({}) return end
	local curTeam = self.pnlLeft.Items[self.pnlRight.job.team]
	if not curTeam or curTeam:GetDisabled() then
		for k,v in ipairs(self.pnlLeft.Items) do
			if v:GetDisabled() then continue end
			self.pnlRight:updateInfo(v.DarkRPItem)
			return
		end
		self.pnlRight:updateInfo({})
	end
end

function PANEL:fillData()
	for i, job in ipairs(RPExtraTeams) do
		local item = vgui.Create("F4MenuJobButton")
		item:setDarkRPItem(job)
		item.DoClick = fn.Compose{fn.Curry(self.pnlRight.updateInfo, 2)(self.pnlRight), fn.Curry(fn.GetValue, 3)("DarkRPItem")(item)}
		self.pnlLeft:AddItem(item)
		item:Refresh()
	end
end

derma.DefineControl("F4MenuJobs", "", PANEL, "DPanel")
