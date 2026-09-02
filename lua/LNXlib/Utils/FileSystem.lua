local FileSystem = {}
local WorkDir = engine.GetGameDir() .. "/../lnxLib/"

-- io is blocked; filesystem.ReadFile is game-dir sandboxed, nil if missing.
function FileSystem.Read(path)
    return filesystem.ReadFile(path)
end

function FileSystem.Write(path, content)
    return filesystem.WriteFile(path, content)
end

-- os.remove is blocked and filesystem has no delete; best-effort no-op.
function FileSystem.Delete(path)
    print("lnxLib FileSystem.Delete: not supported (blocked): " .. tostring(path))
    return false
end

-- GetFileAttributes returns -1 (INVALID_FILE_ATTRIBUTES) when missing.
function FileSystem.Exists(path)
    return filesystem.GetFileAttributes(path) ~= -1
end

function FileSystem.GetWorkDir()
    if not FileSystem.Exists(WorkDir) then
        filesystem.CreateDirectory(WorkDir)
    end

    return WorkDir
end

return FileSystem
