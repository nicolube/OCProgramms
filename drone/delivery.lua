local function getComponent(type) return component.proxy(component.list(type)()) end

chunkloader = getComponent("chunkloader")
drone = getComponent("drone")
internet = getComponent("internet")
modem = getComponent("modem")

-- Setup
drone.setLightColor(0xFFFF00)
drone.setStatusText("Booting...")

sites = {bottom = 0, top = 1, back = 2, front = 3, right = 4, left = 5}

chunkloader.setActive(true)

local host = "nico-alpha.server.gamers.yt"
local port = 22001
modemAddr = component.list("modem")();
local sock;

local function sleep(time)
    local s = computer.uptime() + time
    local color = drone.getLightColor()
    drone.setLightColor(0x880088)
    while computer.uptime() < s do drone.setStatusText(drone.getStatusText()) end
    drone.setLightColor(color)
end

local cTry = 0;
local function connect()
    cTry = cTry + 1
    drone.setStatusText("Connecting...\n" .. cTry .. "    ")
    if sock then sock.close() end
    sleep(2)
    sock = internet.connect(host, port)
    sock.finishConnect()
end
connect()
local result = ""

local function run()
    drone.setStatusText("Run...\n" .. computer.uptime() .. "     ")
    local read = sock.read()
    for i = 1, #read do
        local c = read:sub(i, i)
        if c == "\n" then
            local _, callback = pcall(load(result))
            sock.write(tostring(callback))
            result = ""
        else
            result = result .. c
        end
    end
end

while true do
    local status, msg = sock.finishConnect()
    if not status then
        drone.setLightColor(0xff0000)
        connect()
    end
    local sType, _, _ = computer.pullSignal(0)
    if not pcall(run) then
        drone.setLightColor(0xff0000)
        connect()
    else
        drone.setLightColor(0x00FF00)
    end
end
