--!strict

local RunService = game:GetService("RunService")

export type Module = {
	Priority: number?,
	Init: ((self: any) -> ())?,
	Start: ((self: any) -> ())?,
	[string]: any,
}

type Entry = {
	Name: string,
	Module: Module,
	Priority: number,
	Failed: boolean,
}

local TIEMPO_AVISO_INIT = 1
local TIEMPO_AVISO_START = 5

local registry: { [string]: Module } = {}
local entries: { Entry } = {}
local proxies: { [string]: any } = {}
local readyCallbacks: { () -> () } = {}
local started = false
local ready = false

local Framework = {}

Framework.IsServer = RunService:IsServer()
Framework.Debug = RunService:IsStudio()

local function register(moduleScript: ModuleScript)
	local name = moduleScript.Name
	if registry[name] ~= nil then
		error(`[Framework] Módulo duplicado "{name}": {moduleScript:GetFullName()}`, 0)
	end

	local ok, result = xpcall(function()
		return require(moduleScript)
	end, debug.traceback)

	if not ok then
		warn(`[Framework] No se pudo cargar "{name}":\n{result}`)
		return
	end
	if type(result) ~= "table" then
		warn(`[Framework] "{name}" debe devolver una tabla`)
		return
	end

	local module = result :: Module
	registry[name] = module
	table.insert(entries, {
		Name = name,
		Module = module,
		Priority = module.Priority or 0,
		Failed = false,
	})
end

local function ejecutarInit(entry: Entry)
	local init = entry.Module.Init
	if type(init) ~= "function" then
		return
	end

	local inicio = os.clock()
	local ok, err = xpcall(init, debug.traceback, entry.Module)
	if not ok then
		entry.Failed = true
		warn(`[Framework] Error en {entry.Name}:Init\n{err}`)
		return
	end
	if os.clock() - inicio > TIEMPO_AVISO_INIT then
		warn(`[Framework] {entry.Name}:Init tardó más de {TIEMPO_AVISO_INIT}s y bloquea el arranque`)
	end
end

local function ejecutarStart(entry: Entry)
	local start = entry.Module.Start
	if type(start) ~= "function" then
		return
	end

	local aviso = task.delay(TIEMPO_AVISO_START, function()
		warn(`[Framework] {entry.Name}:Start lleva más de {TIEMPO_AVISO_START}s sin terminar`)
	end)
	local ok, err = xpcall(start, debug.traceback, entry.Module)
	task.cancel(aviso)

	if not ok then
		warn(`[Framework] Error en {entry.Name}:Start\n{err}`)
	end
end

-- Carga los ModuleScripts de una carpeta. Ignora los que empiezan con "_".
-- Con deep = true también carga los de subcarpetas.
function Framework.LoadFolder(folder: Instance, deep: boolean?)
	if started then
		error("[Framework] LoadFolder debe llamarse antes de Start", 2)
	end

	local children = if deep then folder:GetDescendants() else folder:GetChildren()
	for _, child in children do
		if child:IsA("ModuleScript") and string.sub(child.Name, 1, 1) ~= "_" then
			register(child :: ModuleScript)
		end
	end
end

function Framework.Get(name: string): any
	local module = registry[name]
	if module == nil then
		local disponibles = {}
		for registrado in registry do
			table.insert(disponibles, registrado)
		end
		table.sort(disponibles)
		error(`[Framework] No existe el módulo "{name}". Disponibles: {table.concat(disponibles, ", ")}`, 2)
	end
	return module
end

function Framework.Use(name: string): any
	local cached = proxies[name]
	if cached ~= nil then
		return cached
	end

	local resolved: Module? = nil
	local function resolver(): Module
		local module = resolved
		if module == nil then
			module = Framework.Get(name) :: Module
			resolved = module
		end
		return module
	end

	local proxy = setmetatable({}, {
		__index = function(_, key)
			return resolver()[key]
		end,
		__newindex = function(_, key, value)
			resolver()[key] = value
		end,
	})

	proxies[name] = proxy
	return proxy
end

function Framework.Start()
	if started then
		warn("[Framework] Start ya fue llamado")
		return
	end
	started = true
	local inicio = os.clock()

	table.sort(entries, function(a, b)
		if a.Priority ~= b.Priority then
			return a.Priority > b.Priority
		end
		return a.Name < b.Name
	end)

	for _, entry in entries do
		ejecutarInit(entry)
	end
	for _, entry in entries do
		if not entry.Failed then
			task.spawn(ejecutarStart, entry)
		end
	end

	ready = true
	for _, callback in readyCallbacks do
		task.spawn(callback)
	end
	table.clear(readyCallbacks)

	if Framework.Debug then
		local lado = if Framework.IsServer then "Servidor" else "Cliente"
		local ms = math.round((os.clock() - inicio) * 1000)
		print(`[Framework] {lado}: {#entries} módulos iniciados en {ms} ms`)
	end
end

function Framework.IsReady(): boolean
	return ready
end

-- Ejecuta el callback cuando todos los Init terminaron y los Start fueron lanzados.
function Framework.OnReady(callback: () -> ())
	if ready then
		task.spawn(callback)
	else
		table.insert(readyCallbacks, callback)
	end
end

return Framework
