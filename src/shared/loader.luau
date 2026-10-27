--!strict
local Loader = {}

type Module = {
	Init: (() -> ())?,
	Start: (() -> ())?,
}

function Loader.LoadFolder(folder: Instance): { Module }
	local modules: { Module } = {}
	for _, child in folder:GetChildren() do
		if child:IsA("ModuleScript") then
			table.insert(modules, require(child) :: Module)
		end
	end
	return modules
end

function Loader.Start(modules: { Module })
	for _, m in modules do
		if m.Init then
			m.Init()
		end
	end
	for _, m in modules do
		if m.Start then
			task.spawn(m.Start)
		end
	end
end

return Loader