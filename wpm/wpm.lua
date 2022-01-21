local component = require "component"
local serialization = require "serialization"
local shell = require "shell"
local text = require "text"
local fs = require "filesystem"
local internet = require("internet")

local function print(txt)
    io.write(txt.."\n")
end 
local function printErr(txt)
    io.stderr:write(txt.."\n")
end 

local function handleGet(url)
    local res = internet.request(url)
    while res.finishConnect() == false do end
    local code, msg, header = res.response()
    local result = {["code"] = code, ["msg"] = msg, ["header"] = header, ["data"] = nil}
    if code == 200 then
        local data = res.read()
        result["data"] = serialization.unserialize(data)
    end
    return result
end
 
local function installPackage(url)
    local rsp = handleGet(url.."/".."package.cfg")
    if rsp.code == 404 then
        printErr("Package not found!")
        return
    elseif rsp.code ~= 200 then
        printErr("An error has occurred! "..rsp.code)
        return
    end
    print("Installing package: "..rsp.data.name)
    print("Version: "..rsp.data.version)
    print("Author: "..rsp.data.author)
    print("")

    if rsp.data.dependencies then
        print("Installing dependencies...")
        for i, dep in pairs(rsp.data.dependencies) do
            installPackage(dep)
        end
    end

    print("Installing files: "..rsp.data.name.."\n")
    
    for file, target in pairs(rsp.data.files) do
        local res = internet.request(url.."/"..file)
        while res.finishConnect() == false do end
        
        local code, msg, header = res.response()
        if (code == nil) then
            code = 404
        end
        if code == 200 then
            if fs.exists(target) == false then
                fs.makeDirectory(target)
            end
            print(url.."/"..file.." -> "..target.."/"..file)
            local file = fs.open(target.."/"..file, "w")
            for data in res do
                file:write(data)
            end
            file:close()
        else
            printErr("Failed to download: "..url.."/"..file..": "..code)
        end
    end
end

local args, options = shell.parse(...)

local url = text.trim(args[1])

installPackage(url)